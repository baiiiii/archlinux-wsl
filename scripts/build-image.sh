#!/bin/bash

set -euo pipefail

# Fixed TZ to ensure consistency
export TZ=UTC

declare -r WORKDIR="$1"
declare -r BUILDDIR="$WORKDIR/build"
declare -r OUTPUTDIR="$WORKDIR/output"
declare -r IMAGE_VERSION="$2"
ARCHIVE_SNAPSHOT=$(date -u -d "$(awk -F. '{print $1"-"$2"-"$3}' <<< "$IMAGE_VERSION") -1 day" +"%Y/%m/%d")
readonly ARCHIVE_SNAPSHOT
SOURCE_DATE_EPOCH=$(date -u -d "$(awk -F. '{print $1"-"$2"-"$3}' <<< "$IMAGE_VERSION")" +"%s")
readonly SOURCE_DATE_EPOCH
export SOURCE_DATE_EPOCH

# For eventual debugging purposes
echo -e "ARCHIVE_SNAPSHOT: ${ARCHIVE_SNAPSHOT}\nSOURCE_DATE_EPOCH: ${SOURCE_DATE_EPOCH}"

mkdir -vp "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks"
find /usr/share/libalpm/hooks -exec ln -sf /dev/null "$BUILDDIR/alpm-hooks"{} \;

mkdir -vp "$BUILDDIR/var/lib/pacman/" "$OUTPUTDIR"
install -Dm 644 "/usr/share/devtools/pacman.conf.d/extra.conf" "$BUILDDIR/etc/pacman.conf"

sed 's/Include = /&rootfs/g' < "$BUILDDIR/etc/pacman.conf" > "$WORKDIR/pacman.conf"

cp --recursive --preserve=timestamps rootfs/* "$BUILDDIR/"
ln -sf /usr/lib/os-release "$BUILDDIR/etc/os-release"

# Use archived repo snapshot from archive.archlinux.org for reproducible builds
sed -i "1iServer = https://archive.archlinux.org/repos/$ARCHIVE_SNAPSHOT/\\\$repo/os/\\\$arch" rootfs/etc/pacman.d/mirrorlist

fakechroot -- fakeroot -- \
    pacman -Sy --disable-sandbox-filesystem -r "$BUILDDIR" \
        --logfile /dev/null \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config "$WORKDIR/pacman.conf" \
        --noscriptlet \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" base

fakechroot -- fakeroot -- chroot "$BUILDDIR" update-ca-trust
fakechroot -- fakeroot -- chroot "$BUILDDIR" pacman-key --init
fakechroot -- fakeroot -- chroot "$BUILDDIR" pacman-key --populate
fakechroot -- fakeroot -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"
fakechroot -- fakeroot -- chroot "$BUILDDIR" /usr/bin/systemctl mask \
	systemd-firstboot \
	console-getty \
	tmp.mount \
	systemd-tmpfiles-setup-dev-early \
	systemd-tmpfiles-setup-dev \
	systemd-tmpfiles-setup

# Disable getty template units to prevent service failures caused by shared Hyper-V TTY devices across WSL instances
# See https://github.com/microsoft/WSL/issues/13595
ln -sf /dev/null "$BUILDDIR/etc/systemd/system/getty@.service"
ln -sf /dev/null "$BUILDDIR/etc/systemd/system/serial-getty@.service"

# Clear pacman keyring for reproducible builds
 rm -rf "$BUILDDIR"/etc/pacman.d/gnupg/*

# Normalize mtimes
find "$BUILDDIR" -exec touch --no-dereference --date="@$SOURCE_DATE_EPOCH" {} +

# Use fakeroot to map the gid / uid of the builder process to root
# See https://gitlab.archlinux.org/archlinux/archlinux-docker/-/issues/22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        --mtime="@$SOURCE_DATE_EPOCH" \
        --clamp-mtime \
        --sort=name \
        --pax-option=delete=atime,delete=ctime \
        --exclude-from=scripts/exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/archlinux-$IMAGE_VERSION.tar"

cd "$OUTPUTDIR"
xz -T0 -9 "archlinux-$IMAGE_VERSION.tar"
mv -v "archlinux-$IMAGE_VERSION.tar.xz" "archlinux-$IMAGE_VERSION.wsl"
sha256sum "archlinux-$IMAGE_VERSION.wsl" > "archlinux-$IMAGE_VERSION.wsl.SHA256"
echo "The sha256 hash of the image is:"
cat "archlinux-$IMAGE_VERSION.wsl.SHA256"
