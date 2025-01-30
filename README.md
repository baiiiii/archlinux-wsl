# Arch Linux WSL Image

⚠️⚠️⚠️ **DISCLAIMER:**

> This is not official. Arch Linux on WSL is currently unsupported. This repo currently is a proposal, see [the related thread](https://lists.archlinux.org/archives/list/arch-dev-public@lists.archlinux.org/thread/73A4BK7YK4BJBVXGMN2I5CROQAWI53VZ/).  
> Some of the stuff described here might not be implemented / working yet (and there's currently no guarantee that they ever will).

[![CI Status](https://gitlab.archlinux.org/antiz/archlinux-wsl/badges/master/pipeline.svg)](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/pipelines)

Arch Linux provides a WSL image.

Images are built & [released](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases) monthly (via [GitLab CI schedule](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/pipeline_schedules)) and aim to provide the simplest but complete system to offer an outright Arch Linux experience with WSL (including `systemd` support out of the box).

While images are built regularly, it is strongly recommended running `pacman -Syu` right after the first launch due to the rolling release nature of Arch Linux.

---
⚠️⚠️⚠️ **NOTE:**

> For Security Reasons, this image strips the pacman lsign key.  
> This is because the same key would be spread to all Arch WSL installation of the same image, allowing for malicious actors to inject packages (via, for example, a man-in-the-middle). In order to create a lsign-key run `pacman-key --init` on the first run of the image (if you need one), but be careful to not redistribute that key.
---

## Installation

### Automated install

From a Windows system with WSL2 installed, run the following command in a PowerShell prompt:

```powershell
wsl --install ArchLinux
```

You can then run Arch Linux in WSL via the `ArchLinux` application from the Start menu, or by running `wsl -d ArchLinux` in a PowerShell prompt.

### Manual install

#### WSL 2.4.4 or greater

Download the Arch Linux ".wsl" image from [the latest release](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases/permalink/latest) and double-click on it to start the installation.

You can then run Arch Linux in WSL via the `ArchLinux` application from the Start menu, or by running `wsl -d ArchLinux` in a PowerShell prompt.

#### WSL prior to 2.4.4

Download the Arch Linux ".wsl" image from [the latest release](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases/permalink/latest) and run the following command in a PowerShell prompt:

```powershell
wsl --import <Distro name> <Install location> <WSL image>
```

For instance:

```powershell
wsl --import ArchLinux C:\Users\<Username>\Documents\WSL\ArchLinux C:\Users\<Username>\Downloads\archlinux-2025.01.01.wsl
```

You can then run Arch Linux in WSL via the `ArchLinux` application from the Start menu, or by running `wsl -d ArchLinux` in a PowerShell prompt.  
Make sure to execute the first setup script by running `/etc/wsl-first-setup.sh` right after the first launch.

## Building your own image

This repository contains all scripts and files needed to create a WSL image for Arch Linux.

### Dependencies

Install the following Arch Linux packages:

- make
- devtools
- fakechroot
- fakeroot

### Usage

Run `make` to build a new image (which can be then found in the `output` directory).  
Optionally, run `make clean` to remove every directories, files & artifacts generated during build (including the built image itself).
