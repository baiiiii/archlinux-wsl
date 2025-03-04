#!/bin/bash

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at https://gitlab.archlinux.org/archlinux/archlinux-wsl.

It provides systemd support.
However, there are known pending issues that may require additional actions for systemd to work properly.
See https://gitlab.archlinux.org/archlinux/archlinux-wsl#known-issues for more details.

Note that WSL 1 is not supported.

Please, report bugs at https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/issues.
See also the related Arch Wiki page at https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF

# Generate pacman lsign key
echo -e "\nGenerating pacman lsign key..." && pacman-key --init 2> /dev/null && echo "Done"

# See https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/issues/3
systemctl cancel "$(systemctl list-jobs | grep systemd-firstboot.service | awk '{print $1}')" 2> /dev/null || true
