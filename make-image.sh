#!/bin/bash

set -euo pipefail

declare -r WRAPPER="fakechroot -- fakeroot"

today=$(date +"%Y.%m.%d")
declare -r DATE="$today"

declare -r BUILDDIR="$1"
declare -r OUTPUTDIR="$2"

mkdir -vp "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks"
find /usr/share/libalpm/hooks -exec ln -sf /dev/null "$BUILDDIR/alpm-hooks"{} \;

mkdir -vp "$BUILDDIR/var/lib/pacman/" "$OUTPUTDIR"
install -Dm 644 "/usr/share/devtools/pacman.conf.d/extra.conf" "$BUILDDIR/etc/pacman.conf"

sed 's/Include = /&rootfs/g' < "$BUILDDIR/etc/pacman.conf" > pacman.conf

cp --recursive --preserve=timestamps rootfs/* "$BUILDDIR/"
ln -sf /usr/lib/os-release "$BUILDDIR/etc/os-release"

$WRAPPER -- \
    pacman -Sy -r "$BUILDDIR" \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config pacman.conf \
        --noscriptlet \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" base

$WRAPPER -- chroot "$BUILDDIR" update-ca-trust
$WRAPPER -- chroot "$BUILDDIR" pacman-key --init
$WRAPPER -- chroot "$BUILDDIR" pacman-key --populate
$WRAPPER -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"

# fakeroot to map the gid/uid of the builder process to root
# See https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        --exclude-from=exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/archlinux-$DATE.tar"

cd "$OUTPUTDIR"
zstd --rm --long -T0 -8 "archlinux-$DATE.tar"
mv "archlinux-$DATE.tar.zst" "archlinux-$DATE.wsl"
sha256sum "archlinux-$DATE.wsl" > "archlinux-$DATE.wsl.SHA256"
