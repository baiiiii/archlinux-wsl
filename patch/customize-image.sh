#!/bin/bash
#
# 镜像定制脚本，由 build-image.sh 在装完 base 之后调用。
#
# 相对上游新增的镜像内容全部集中在这里，build-image.sh 保持与上游一致
# （只多一行对本脚本的调用），便于日后与上游对比，也便于单独阅读定制逻辑。
#
# 用法：customize-image.sh <构建树目录> <工作目录>

set -euo pipefail

declare -r BUILDDIR="$1"
declare -r WORKDIR="$2"
declare -r PACMAN_CONF="$WORKDIR/pacman.conf"

# ---------- 可配置项 ----------

# 追加到 base 之上的软件包
declare -ra PKGS_EXTRA=(
    # 基础工具
    sudo xdg-utils
    # WSLg GPU 加速：mesa 提供 d3d12 Gallium 驱动，vulkan-dzn 是微软直通的实验性 Vulkan 驱动
    mesa-utils vulkan-dzn vulkan-icd-loader
    # AppImage / Electron 应用在最小系统上缺失的运行时库
    fuse2 nspr nss at-spi2-core libcups gtk3 libxcomposite libxdamage libxfixes libxrandr alsa-lib
    # 输入法：fcitx5-im 含本体与 GTK/Qt 前端，fcitx5-chinese-addons 提供拼音等中文引擎
    fcitx5-im fcitx5-chinese-addons
)

# 等宽字体：Maple Mono，Normal 预设字形（接近 JetBrains Mono，带斜杠零）、关闭连字、
# 含 Nerd Font 图标与中日字形。只取四个常用字重：整套 16 个会让镜像白白大出一倍，
# Medium / SemiBold 这两档极少被显式调用，界面里的“中粗”字号由 fontconfig 取 Bold 顶上。
# 版本钉在 tag 上并用 sha256 校验，保证下载内容确定、构建仍可复现
declare -r MONO_FONT_URL="https://github.com/subframe7536/maple-font/releases/download/v7.9/MapleMonoNormalNL-NF-CN.zip"
declare -r MONO_FONT_SHA256="af8082c484cb1103da6c2efa4b76f403fe342f9a3ac81ff665b8c6c66c2f8863"
declare -r MONO_FONT_DIR="/usr/local/share/fonts/maple-mono"
declare -ra MONO_FONT_WEIGHTS=(Regular Bold Italic BoldItalic)

# 界面字体：Sarasa UI SC（更纱黑体的界面变体）。中文按正常比例排版，
# 不像等宽字体那样按 2:1 撑宽，所以适合做界面字体
declare -r SANS_FONT_URL="https://github.com/be5invis/Sarasa-Gothic/releases/download/v1.0.41/SarasaUiSC-TTF-1.0.41.7z"
declare -r SANS_FONT_SHA256="568015e578037cdcfb7c55d522f7e861e11ecd304824d6c94965cbb2187a8d78"
declare -r SANS_FONT_DIR="/usr/local/share/fonts/sarasa-ui-sc"
declare -ra SANS_FONT_WEIGHTS=(Regular Bold Italic BoldItalic)

# 默认登录用户，由 /etc/wsl.conf 的 [user] default 指定
# 不设密码：/etc/shadow 里不会有随机 salt，镜像逐位可复现不受影响
declare -r NEW_USER="arch"

# ---------- 安装追加软件包 ----------
#
# --assume-installed qt6-webengine：fcitx5-chinese-addons 把它声明为强制依赖，
# 连带拽进 qt6-declarative / qt6-webchannel / qt6-positioning，装完合计 421 MiB、
# 进镜像压缩后约 140 MiB，但这里只是用来打中文，根本用不到 Chromium 内核。
# 让 pacman 认为它已安装即可跳过整条链；受影响的只有 configtool 里的拼音词典管理
# 插件（libpinyindictmanager.so），输入法核心不受影响。
#
# 注意：这个假设不会写进 pacman 数据库，所以日后 fcitx5-chinese-addons 自身升级时，
# pacman 会重新解析依赖并把 qt6-webengine 装回来。要长期避免需要在 pacman.conf 里
# IgnorePkg 掉该包。
echo -e "\n-- Installing extra packages --\n"
fakechroot -- fakeroot -- \
    pacman -S --disable-sandbox-filesystem -r "$BUILDDIR" \
        --logfile /dev/null \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config "$PACMAN_CONF" \
        --noscriptlet \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" \
        --assume-installed qt6-webengine \
        "${PKGS_EXTRA[@]}"

# ---------- 修复 fontconfig 的配置符号链接 ----------
# pacman 以 -r 模式安装时，包的 .install 脚本按*宿主机*的构建路径建符号链接，例如
#   /etc/fonts/conf.d/51-local.conf ->
#   /__w/<repo>/<repo>/workdir/build/usr/share/fontconfig/conf.default/51-local.conf
# 这个路径在镜像里并不存在，于是 conf.d 下 22 个配置全成了断链：通用族别名
# （45-latin / 60-latin / 49-sansserif / 65-nonlatin 等）失效，51-local.conf 读不到，
# 连 /etc/fonts/local.conf 里的自定义字体规则也一并消失，界面字体退化成默认回退。
# 这里按镜像内的路径重建这些链接。
echo -e "\n-- Fixing fontconfig config symlinks --\n"
relinked=0
for link in "$BUILDDIR"/etc/fonts/conf.d/*.conf; do
    [[ -L "$link" ]] || continue
    ln -sfn "/usr/share/fontconfig/conf.default/${link##*/}" "$link"
    relinked=$((relinked + 1))
done
echo "    relinked ${relinked} entries under /etc/fonts/conf.d"

# 校验链接目标是否都指向镜像内路径。这里只做字符串比较、不解析链接：
# 链接目标是镜像内的绝对路径，在构建机上并不存在，
# 任何“跟随链接判断是否存在”的检查都会误报（find -xtype l 与 chroot 内 fc-pattern 都踩过）。
bad_links=""
for link in "$BUILDDIR"/etc/fonts/conf.d/*.conf; do
    target=$(readlink "$link")
    case "$target" in
        /usr/share/fontconfig/conf.default/*) ;;
        *) bad_links+="        ${link##*/} -> ${target}"$'\n' ;;
    esac
done
if [[ -n "$bad_links" ]]; then
    echo "!! /etc/fonts/conf.d 下仍有指向镜像外路径的配置链接：" >&2
    printf '%s' "$bad_links" >&2
    exit 1
fi
[[ -f "$BUILDDIR/etc/fonts/local.conf" ]] || { echo "!! /etc/fonts/local.conf 不在镜像里" >&2; exit 1; }
echo "    /etc/fonts/conf.d 下 $(find "$BUILDDIR/etc/fonts/conf.d" -name '*.conf' | wc -l) 个配置链接均指向镜像内，local.conf 就位"

# ---------- 安装字体 ----------
# 两个字体包都在构建时从上游 release 下载，下载与解压都在 chroot 之外完成，
# 只把选定的 TTF 装进镜像。
echo -e "\n-- Installing fonts --\n"
FONTDIR="$WORKDIR/fonts"
mkdir -vp "$FONTDIR"

# 等宽字体：Maple Mono Normal NL NF CN
curl -fsSL -o "$FONTDIR/maple-mono.zip" "$MONO_FONT_URL"
echo "${MONO_FONT_SHA256}  ${FONTDIR}/maple-mono.zip" | sha256sum --check
unzip -q -o "$FONTDIR/maple-mono.zip" -d "$FONTDIR/maple-mono"
install -d -m 755 "$BUILDDIR$MONO_FONT_DIR"
for weight in "${MONO_FONT_WEIGHTS[@]}"; do
    install -m 644 "$FONTDIR/maple-mono/MapleMonoNormalNL-NF-CN-${weight}.ttf" "$BUILDDIR$MONO_FONT_DIR/"
done
echo "Installed $(find "$BUILDDIR$MONO_FONT_DIR" -type f | wc -l) files into $MONO_FONT_DIR"

# 界面字体：Sarasa UI SC。上游只提供 7z，所以构建依赖里要有 p7zip
curl -fsSL -o "$FONTDIR/sarasa-ui-sc.7z" "$SANS_FONT_URL"
echo "${SANS_FONT_SHA256}  ${FONTDIR}/sarasa-ui-sc.7z" | sha256sum --check
7z x -y -o"$FONTDIR/sarasa-ui-sc" "$FONTDIR/sarasa-ui-sc.7z" > /dev/null
install -d -m 755 "$BUILDDIR$SANS_FONT_DIR"
for weight in "${SANS_FONT_WEIGHTS[@]}"; do
    find "$FONTDIR/sarasa-ui-sc" -name "SarasaUiSC-${weight}.ttf" \
        -exec install -m 644 -t "$BUILDDIR$SANS_FONT_DIR" {} +
done
# find 匹配不到文件时不会报错，所以这里显式核对数量，避免悄悄少装
installed_sans=$(find "$BUILDDIR$SANS_FONT_DIR" -type f | wc -l)
if [[ "$installed_sans" -ne "${#SANS_FONT_WEIGHTS[@]}" ]]; then
    echo "!! Sarasa UI SC 只装入 ${installed_sans} 个文件，期望 ${#SANS_FONT_WEIGHTS[@]} 个，请检查压缩包内的文件名" >&2
    exit 1
fi
echo "Installed ${installed_sans} files into $SANS_FONT_DIR"

# ---------- 配置中文 locale ----------
# 在装完包之后再改 locale.gen：glibc 的 /etc/locale.gen 是 backup 文件，
# 提前改会在 pacman 安装时产生冲突或留下 .pacnew。
# LANG 本身来自 rootfs/etc/locale.conf（zh_CN.UTF-8），这里只负责生成 locale 数据。
echo -e "\n-- Generating locale --\n"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' "$BUILDDIR/etc/locale.gen"
sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' "$BUILDDIR/etc/locale.gen"
fakechroot -- fakeroot -- chroot "$BUILDDIR" locale-gen
# WSL 会按 Windows 的区域设置注入 locale，它认的是 /etc/default/locale，
# 做这个符号链接，让镜像里写死的 LANG=zh_CN.UTF-8 说了算
ln -sf /etc/locale.conf "$BUILDDIR/etc/default/locale"

# ---------- 创建默认用户 ----------
echo -e "\n-- Creating user ${NEW_USER} --\n"
fakechroot -- fakeroot -- chroot "$BUILDDIR" \
    /usr/bin/useradd -m -G wheel -s /bin/bash "$NEW_USER"
fakechroot -- fakeroot -- chroot "$BUILDDIR" \
    install -d -m 700 "/home/$NEW_USER/.config" "/home/$NEW_USER/.cache" "/home/$NEW_USER/.local/share"

# git 只记录可执行位，sudoers 与输入法配置的权限位要在构建时补回来
chmod 440 "$BUILDDIR/etc/sudoers.d/wheel"
chmod 700 "$BUILDDIR/etc/skel/.config/fcitx5"
chmod 600 "$BUILDDIR/etc/skel/.config/fcitx5/profile"

# 家目录属主。useradd 是在 fakeroot 会话里跑的，那次会话的虚拟属主记录不会保留到
# 打包阶段，所以这里在 fakeroot 之外真实 chown 一次（CI 里构建者是 root，有效）。
# 本地以普通用户构建时这一步会失败，此时属主由打包阶段决定，不影响功能。
NEW_USER_UID=$(fakechroot -- fakeroot -- chroot "$BUILDDIR" id -u "$NEW_USER")
NEW_USER_GID=$(fakechroot -- fakeroot -- chroot "$BUILDDIR" id -g "$NEW_USER")
echo "    ${NEW_USER} -> uid ${NEW_USER_UID}, gid ${NEW_USER_GID}"
if ! chown -R "${NEW_USER_UID}:${NEW_USER_GID}" "$BUILDDIR/home/$NEW_USER" 2>/dev/null; then
    echo "    (非 root 构建，家目录属主留给打包阶段处理)"
fi

# 校验家目录属主确实落在用户身上。若属主是 root，该用户登录后连 chdir 都进不去
# （表现为 shell 落在 /、写 ~/.bash_profile 报权限不够），必须在构建期就拦住，
# 而不是等装完镜像才发现。上一版把 chown 写在 fakeroot 会话里，虚拟属主不落盘，
# 打包出来的家目录就归了 root。
home_owner=$(stat -c '%u:%g' "$BUILDDIR/home/$NEW_USER" 2>/dev/null || echo '?')
if [[ "$home_owner" != "${NEW_USER_UID}:${NEW_USER_GID}" ]]; then
    echo "!! /home/${NEW_USER} 的属主是 ${home_owner}，期望 ${NEW_USER_UID}:${NEW_USER_GID}" >&2
    exit 1
fi
echo "    家目录属主 ${home_owner} 已就位"

# ---------- 校验字体配置 ----------
# 只做文件级检查，不在 chroot 里跑 fc-pattern/fc-match：conf.d 下的链接是镜像内
# 绝对路径，fakechroot 拦不住内核解析符号链接，在构建机上必然落到不存在的位置。
# 规则是否生效已在真实 WSL 里用 fc-pattern -c 验证：sans-serif/serif → Sarasa UI SC，
# monospace → Maple Mono Normal NL NF CN。
echo -e "\n-- Font config checks --\n"
local_conf="$BUILDDIR/etc/fonts/local.conf"
for family in sans-serif serif monospace; do
    if ! grep -q "<string>${family}</string>" "$local_conf"; then
        echo "!! local.conf 里缺少 ${family} 的规则" >&2
        exit 1
    fi
done
echo "    local.conf 覆盖 sans-serif / serif / monospace 三条规则"
echo "    内置字体："
find "$BUILDDIR$SANS_FONT_DIR" "$BUILDDIR$MONO_FONT_DIR" -name '*.ttf' | sed "s|$BUILDDIR|        |"

# ---------- 清理构建痕迹 ----------
# pacman 对本地已修改过的配置文件会留下 .pacnew / .pacsave，清理掉避免干扰
find "$BUILDDIR/etc" \( -name '*.pacnew' -o -name '*.pacsave' \) -delete

echo -e "\n-- Customization done --\n"
