#!/bin/bash

# See https://gitlab.archlinux.org/antiz/archlinux-wsl/#known-issues
systemctl cancel "$(systemctl list-jobs | grep systemd-firstboot.service | awk '{print $1}')" || true

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at https://gitlab.archlinux.org/archlinux/archlinux-wsl.

It provides systemd support.
However, there are known pending issues that may require additional actions for systemd to work properly.
See https://gitlab.archlinux.org/antiz/archlinux-wsl#known-issues for more details.

For security reasons, this image strips the pacman lsign key.
See the "NOTE:" section at https://gitlab.archlinux.org/antiz/archlinux-wsl for more details.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF
