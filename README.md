# Arch Linux WSL Image

⚠️⚠️⚠️ **DISCLAIMER:**

> This is not official. Arch Linux on WSL is currently unsupported. This repo currently is a proposal, see [the related thread](https://lists.archlinux.org/archives/list/arch-dev-public@lists.archlinux.org/thread/73A4BK7YK4BJBVXGMN2I5CROQAWI53VZ/).  
> Some of the stuff described here might not be implemented / working yet (and there's currently no guarantee that they ever will).

[![CI Status](https://gitlab.archlinux.org/antiz/archlinux-wsl/badges/main/pipeline.svg)](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/pipelines)

Arch Linux provides a WSL image.

Images are built & [released](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases) monthly (via [GitLab CI schedule](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/pipeline_schedules)) and aim to provide the simplest but complete system to offer an outright Arch Linux experience with WSL (including `systemd` support out of the box).

While images are built regularly, it is strongly recommended running `pacman -Syu` right after the first launch due to the rolling release nature of Arch Linux.

---
⚠️⚠️⚠️ **NOTE:**

> For security reasons, this image strips the pacman lsign key.  
> This is because the same key would be spread to all Arch WSL installation of the same image, allowing for malicious actors to inject packages (via, for example, a man-in-the-middle). In order to create a lsign-key (if you need one) run `pacman-key --init` on the first run of the image, but be careful to not redistribute that key.
---

## Installation

### Automated install

From a Windows system with WSL2 installed, run the following command in a PowerShell prompt:

```powershell
wsl --install archlinux
```

You can then run Arch Linux in WSL via the `archlinux` application from the Start menu, or by running `wsl -d archlinux` in a PowerShell prompt.

### Manual install

#### WSL 2.4.4 or greater

Download the Arch Linux ".wsl" image from [the latest release](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases/permalink/latest) and double-click on it to start the installation.

You can then run Arch Linux in WSL via the `archlinux` application from the Start menu, or by running `wsl -d archlinux` in a PowerShell prompt.

#### WSL prior to 2.4.4

Download the Arch Linux ".wsl" image from [the latest release](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/releases/permalink/latest) and run the following command in a PowerShell prompt:

```powershell
wsl --import <Distro name> <Install location> <WSL image>
```

For instance:

```powershell
wsl --import archlinux C:\Users\<Username>\Documents\WSL\archlinux C:\Users\<Username>\Downloads\archlinux-2025.01.01.wsl
```

You can then run Arch Linux in WSL via the `archlinux` application from the Start menu, or by running `wsl -d archlinux` in a PowerShell prompt.  
Make sure to execute the first setup script by running `/usr/lib/wsl/first-setup.sh` right after the first launch.

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

## Known issues

### systemd support

This Arch Linux WSL image provides `systemd` support.  
However, there are known pending issues that may require additional actions for `systemd` to work properly:

#### systemd-firstboot.service hanging

The `systemd-firstboot.service` job [hangs at first boot](https://github.com/yuk7/ArchWSL/issues/356#issuecomment-2039008495), preventing any other systemd services to start.

A workaround is to cancel it by running `systemctl cancel "$(systemctl list-jobs | grep systemd-firstboot.service | awk '{print $1}')"`.  
This is automatically done by the [first-setup script](https://gitlab.archlinux.org/antiz/archlinux-wsl/-/blob/main/rootfs/usr/lib/wsl/first-setup.sh?ref_type=heads) when running the image for the first time.

The actual root cause of this issue (and the eventual proper fix for it) is not known yet.

#### systemd requires plain cgroup v2 support

Currently, WSL2 starts systems [with cgroup v1 support by default](https://github.com/microsoft/WSL/issues/11857) but `systemd` >= 256 [dropped support for it](https://github.com/systemd/systemd/releases/tag/v256) and requires plain cgroup v2 support.

While waiting for WSL2 to start systems with plain cgroup v2 support by default, you can force it by disabling cgroup v1 support in the `%USERPROFILE%/.wslconfig` file on your Windows system (create it if it doesn't exists) with the following content:

```text
[wsl2]
kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1
```
