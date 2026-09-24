#!/bin/bash

# Show some documentation
cat <<EOF
Welcome to the Arch Linux WSL image!

This image is maintained at <https://github.com/baiiiii/archlinux-wsl>.

Please, report bugs at <https://github.com/baiiiii/archlinux-wsl/-/issues>.
Note that WSL 1 is not supported.

For more information about this WSL image and its usage (including "tips and tricks" and troubleshooting steps), see the related Arch Wiki page at <https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL>.

While images are built regularly, it is strongly recommended running "pacman -Syu" right after the first launch due to the rolling release nature of Arch Linux.
EOF

# Initialize pacman keyring at first launch (see the "/!\/!\/!\ Note" at
# https://gitlab.archlinux.org/archlinux/archlinux-docker#principles).
# Keys are NOT generated at build time: the keyring is wiped in the image
# for reproducibility, and runtime is the only place with real entropy.
echo -e "\nGenerating pacman keys..." && pacman-key --init &> /dev/null && echo "Done"
echo -e "\nPopulating keyring..." && pacman-key --populate archlinux &> /dev/null && echo "Done"

# ---------- Create the default user ----------
# The default user is created here, at first launch (OOBE), instead of at
# build time. OOBE runs as real root on the real filesystem, so the home
# directory ownership is correct by construction. Creating it inside the
# build container required fakechroot/fakeroot, whose virtual ownership
# does not survive to the packing stage and produced images where
# /home/<user> belonged to root (symptom: "chdir(/home/arch) failed 13").
#
# NOTE: the user name must match /etc/wsl.conf -> [user] default=arch.
NEW_USER="arch"

if id "$NEW_USER" &>/dev/null; then
    echo -e "\nUser ${NEW_USER} already exists, skipping creation."
else
    echo -e "\nCreating user ${NEW_USER}..."
    # wheel group is guaranteed by systemd-sysusers (basic.conf), which has
    # already run inside this image; -G wheel is therefore safe here.
    useradd -m -G wheel -s /bin/bash "$NEW_USER"
    chmod 700 "/home/${NEW_USER}"

    # Sanity check with an explicit repair step: this script runs as real
    # root, so a chown here always takes effect (unlike in the build
    # container). If ownership were wrong, the login shell would fail with
    # "chdir(/home/...) failed 13" -- fix it now, not after first login.
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
    fi
fi
