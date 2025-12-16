#!/bin/bash

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at <https://gitlab.archlinux.org/archlinux/archlinux-wsl>.

Please, report bugs at <https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/issues>.
Note that WSL 1 is not supported.

For more information about this WSL image and its usage (including "tips and tricks" and troubleshooting steps), see the related Arch Wiki page at <https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL>.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF

# Generate pacman lsign key (see the "/!\/!\/!\ Note" at https://gitlab.archlinux.org/archlinux/archlinux-docker#principles)
echo -e "\nGenerating pacman keys..." && pacman-key --init &> /dev/null && echo "Done"
echo -e "\nPopulating keyring..." && pacman-key --populate archlinux &> /dev/null && echo "Done"
