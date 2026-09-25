#!/bin/bash

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at <https://github.com/baiiiii/archlinux-wsl>.

Please, report bugs at <https://github.com/baiiiii/archlinux-wsl/issues>.
Note that WSL 1 is not supported.

For more information about this WSL image and its usage (including "tips and tricks" and troubleshooting steps), see the related Arch Wiki page at <https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL>.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF

# 首次启动时初始化 pacman 密钥环（见 https://gitlab.archlinux.org/archlinux/archlinux-docker#principles
# 的 "/!\/!\/!\ Note"）。不在构建期生成：镜像为保证可复现将 keyring 清空，运行时才有真实熵源。
echo -e "\nGenerating pacman keys..." && pacman-key --init &> /dev/null && echo "Done"
echo -e "\nPopulating keyring..." && pacman-key --populate archlinux &> /dev/null && echo "Done"

# ---------- 创建默认用户 ----------
# 默认用户在首次启动（OOBE）时创建，而不是构建期：OOBE 以真实 root 在真实文件系统上
# 执行，useradd -m 的家目录属主天然正确；构建容器里 useradd 跑在 fakechroot/fakeroot 下，
# 属主是虚拟记账、打包时不落盘，曾产出 /home/<user> 归 root 的镜像
# （症状：登录报 "chdir(/home/arch) failed 13"）。
#
# 默认用户也不能预置在镜像的 /etc/wsl.conf 里：WSL 在会话一开始（OOBE 之前）就解析
# [user] default，那时用户还不存在，会报 "getpwnam(arch) failed" 并回退到 root。
# 所以这里在创建用户之后再写入 wsl.conf，从下一次启动起生效。
#
# 注意：改名只需同步本文件里的 NEW_USER，wsl.conf 里的 default 由下面自动写入。
NEW_USER="arch"

user_ready=0
if id "$NEW_USER" &>/dev/null; then
    echo -e "\nUser ${NEW_USER} already exists, skipping creation."
    user_ready=1
else
    echo -e "\nCreating user ${NEW_USER}..."
    # wheel 组由 systemd-sysusers（basic.conf）在镜像内建好，-G wheel 在此安全。
    useradd -m -G wheel -s /bin/bash "$NEW_USER"
    chmod 700 "/home/${NEW_USER}"

    # 属主自检 + 显式修复：本脚本以真实 root 运行，这里的 chown 一定落盘
    # （构建容器里则不然）。属主不对时登录会报 "chdir(/home/...) failed 13"，
    # 要在首次登录前修好，而不是之后。
    expected="$(id -u "$NEW_USER"):$(id -g "$NEW_USER")"
    actual="$(stat -c '%u:%g' "/home/${NEW_USER}")"
    if [[ "$actual" != "$expected" ]]; then
        echo "    Home ownership is ${actual}, expected ${expected} -- repairing..."
        chown -R "$expected" "/home/${NEW_USER}"
        actual="$(stat -c '%u:%g' "/home/${NEW_USER}")"
    fi
    if [[ "$actual" != "$expected" ]]; then
        echo "    ERROR: could not fix home ownership (${actual} != ${expected})." >&2
        echo "    The user will not be able to log in. Please report this bug." >&2
    else
        echo "    ${NEW_USER} (uid ${expected%%:*}) ready, home ownership ${actual}."
        user_ready=1
    fi
fi

# ---------- 把默认用户写入 wsl.conf ----------
# 只在镜像缺 [user] 段时追加（幂等）：段已存在说明镜像预置过或用户自己改过配置，
# 两种情况都不该覆盖。useradd 失败（user_ready=0）时不写，保持 root 默认，
# 下次启动会重跑 OOBE 重试创建。
if [[ "$user_ready" == 1 ]] && ! grep -qs '^\[user\]' /etc/wsl.conf; then
    printf '\n[user]\ndefault=%s\n' "$NEW_USER" >> /etc/wsl.conf
    echo -e "\nDefault user set to ${NEW_USER} in /etc/wsl.conf."
    # 本次会话开始时 WSL 已经解析过默认用户（回退为 root），改 wsl.conf 只对
    # 下一次启动生效，明确告诉用户下一步怎么做。
    echo "This session is still running as root."
    echo "Exit and start the distribution again (e.g. \"wsl -d archlinux\") to log in as ${NEW_USER}."
fi
