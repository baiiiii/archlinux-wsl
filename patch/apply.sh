#!/bin/bash
#
# 把 patch/ 里的定制叠加到工作副本上。
#
# 只修改运行时的文件，仓库里的上游文件保持原样，git 历史不受影响。
# 幂等：重复执行结果一致。
#
# 用法：bash patch/apply.sh

set -euo pipefail

cd "$(dirname "$0")/.."
declare -r PATCH_DIR="patch"

# ---------- 1. 在 build-image.sh 里插入定制调用 ----------
# 定制必须发生在「systemd-sysusers 建好系统组」之后、「打包」之前。
# 关键是 wheel 组：useradd -G wheel 依赖它，而该组由 /usr/lib/sysusers.d/basic.conf
# 定义、在 build-image.sh 调用 systemd-sysusers 时才创建。插早了会直接报
# "group 'wheel' does not exist"。
anchor='/usr/bin/systemd-sysusers --root "/"'
insert='bash "$(dirname "$0")/customize-image.sh" "$BUILDDIR" "$WORKDIR"'

if grep -qF 'customize-image.sh' scripts/build-image.sh; then
    echo "build-image.sh 已包含定制调用，跳过插入"
else
    # 用 awk 在锚点所在行之后追加。锚点用子串匹配：上游那行带缩进，
    # 整行相等比较会失配。锚点字符串本身在脚本里唯一（只出现在 base 安装那次）。
    awk -v anchor="$anchor" -v insert="$insert" '
        { print }
        index($0, anchor) { print ""; print insert }
    ' scripts/build-image.sh > scripts/build-image.sh.new
    if ! grep -qF 'customize-image.sh' scripts/build-image.sh.new; then
        echo "!! 在 scripts/build-image.sh 里找不到插入锚点，上游脚本可能已变更：" >&2
        echo "   期望的整行内容：${anchor}" >&2
        rm -f scripts/build-image.sh.new
        exit 1
    fi
    # 用 install 而不是 mv：awk 重定向生成的新文件没有可执行位，
    # 直接 mv 过去会让 scripts/build-image.sh 丢掉可执行位，make 就再也跑不动它
    install -m 755 scripts/build-image.sh.new scripts/build-image.sh
    rm -f scripts/build-image.sh.new
    echo "已在 build-image.sh 的 systemd-sysusers 之后插入定制调用"
fi

# ---------- 2. 放置定制脚本与静态文件 ----------
# 定制脚本用 install -m 755：Windows 上 chmod 进不了 git，可执行位不一定还在，
# 而 build-image.sh 里那行调用本身也写成了 `bash <脚本>`，不依赖可执行位。
install -m 755 "${PATCH_DIR}/customize-image.sh" scripts/customize-image.sh
cp -r "${PATCH_DIR}/rootfs/." rootfs/
echo "已叠加 $(find "${PATCH_DIR}/rootfs" -type f | wc -l) 个静态文件到 rootfs/"

echo "补丁应用完成"
