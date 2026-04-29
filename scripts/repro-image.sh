#!/bin/bash

set -euo pipefail

# Fixed TZ to ensure consistency
export TZ=UTC

declare -r ORIG_WORKDIR="$1"
declare -r ORIG_BUILDDIR="$ORIG_WORKDIR/build"
declare -r ORIG_OUTPUTDIR="$ORIG_WORKDIR/output"
declare -r REPRO_WORKDIR="$2"
declare -r REPRO_OUTPUTDIR="$REPRO_WORKDIR/output"
declare -r IMAGE_VERSION="$3"

echo -e "\n-- Testing the userspace reproducibility --\n"
fakechroot -- fakeroot -- chroot "$ORIG_BUILDDIR" pacman-key --init
fakechroot -- fakeroot -- chroot "$ORIG_BUILDDIR" pacman-key --populate archlinux
fakechroot -- fakeroot -- chroot "$ORIG_BUILDDIR" pacman -Syu --disable-sandbox-filesystem --noconfirm arch-repro-status
fakechroot -- fakeroot -- chroot "$ORIG_BUILDDIR" arch-repro-status

echo -e "\n-- Testing the image reproducibility --\n"
make build WORKDIR="$REPRO_WORKDIR"
echo "The sha256 hash of the reproduced image is:"
cat "$REPRO_OUTPUTDIR/archlinux-$IMAGE_VERSION.wsl.SHA256"
diffoscope "$ORIG_OUTPUTDIR/archlinux-$IMAGE_VERSION.wsl" "$REPRO_OUTPUTDIR/archlinux-$IMAGE_VERSION.wsl" && echo -e "\nImage is reproducible!"
