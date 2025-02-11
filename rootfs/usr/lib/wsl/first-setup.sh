#!/bin/bash

# Cancel the systemd-firstboot.service at first run which hangs forever, preventing any other systemd services to start.
# Canceling it once at first boot is enough to "fix" it permanently.
# The actual root cause of this issue (and the eventual proper fix for it) is not known yet.
# Hopefully we can drop that workaround at some point.
systemctl cancel "$(systemctl list-jobs | grep systemd-firstboot.service | awk '{print $1}')" || true

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at https://gitlab.archlinux.org/archlinux/archlinux-wsl.

While images are regularly built it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.

NOTE:

For Security Reasons, this image strips the pacman lsign key.
This is because the same key would be spread to all Arch WSL installation of the same image, allowing for malicious actors to inject packages (via, for example, a man-in-the-middle). In order to create a lsign-key run "pacman-key --init" on the first run of the image (if you need one), but be careful to not redistribute that key.
EOF
