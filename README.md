# Arch Linux WSL Image

[![CI Status](https://gitlab.archlinux.org/archlinux/archlinux-wsl/badges/main/pipeline.svg)](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/pipelines)

Arch Linux provides a WSL image.

Images are built & released monthly (via [GitLab CI schedule](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/pipeline_schedules)) and aim to provide the simplest but complete system to offer an outright Arch Linux experience with WSL (including `systemd` support).

While images are built regularly, it is strongly recommended running `pacman -Syu` right after the first launch due to the rolling release nature of Arch Linux.

Images are signed using [Sigstore Cosign keyless signing](https://docs.gitlab.com/ci/yaml/signing_examples/).  
An image can be verified with the following command:

```bash
cosign verify-blob archlinux-2025.04.01.121271.wsl --bundle archlinux-2025.04.01.121271.wsl.bundle --certificate-identity "https://gitlab.archlinux.org/archlinux/archlinux-wsl//.gitlab-ci.yml@refs/heads/main" --certificate-oidc-issuer "https://gitlab.archlinux.org"
```

See also the related [Arch Wiki page](https://wiki.archlinux.org/title/Install_Arch_Linux_on_WSL).

## Installation

From a Windows system with [WSL 2 installed](https://learn.microsoft.com/en-us/windows/wsl/install), use one of the following installation methods.  
Note that WSL 1 is **not** supported.

### Automated install

**Warning:** This automated install method is a work in progress and is not yet functional!

Run the following command in a PowerShell prompt:

```powershell
wsl --install archlinux
```

You can then run Arch Linux in WSL via the `archlinux` application from the Start menu, or by running `wsl -d archlinux` in a PowerShell prompt.

### Manual install

#### WSL 2.4.4 or greater

Download the [latest Arch Linux ".wsl" image](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/releases/permalink/latest) and double-click on it to start the installation.

You can then run Arch Linux in WSL via the `archlinux` application from the Start menu, or by running `wsl -d archlinux` in a PowerShell prompt.

#### WSL prior to 2.4.4

Download the [latest Arch Linux ".wsl" image](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/releases/permalink/latest) and run the following command in a PowerShell prompt:

```powershell
wsl --import <Distro name> <Install location> <WSL image>
```

For instance:

```powershell
wsl --import archlinux C:\Users\<Username>\Documents\WSL\archlinux C:\Users\<Username>\Downloads\archlinux-2025.04.01.121271.wsl
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

Run `make` to build a new image (which can be then found in the `workdir/output` directory).  
Optionally, run `make clean` afterwards to remove every directories, files & artifacts generated during build (including the built image itself).

## Known issues

### systemd support

This Arch Linux WSL image provides `systemd` support.  
However, there are known pending issues that may require additional actions for `systemd` to work properly:

#### systemd-firstboot.service hanging

The `systemd-firstboot.service` job hangs at first boot, preventing any other systemd services to start.

While waiting for the actual root cause of this issue (and a proper fix for it) to be identified, a workaround is automatically applied by the [first-setup script](https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/blob/main/rootfs/usr/lib/wsl/first-setup.sh?ref_type=heads) when running the image for the first time, so you shouldn't have to do anything on that front.

See <https://gitlab.archlinux.org/archlinux/archlinux-wsl/-/issues/3> for more details.

#### systemd requires plain cgroup v2 support

Currently, WSL starts systems [with cgroup v1 support by default](https://github.com/microsoft/WSL/issues/11857) but `systemd` >= 256 [dropped support for it](https://github.com/systemd/systemd/releases/tag/v256) and requires plain cgroup v2 support.

While waiting for WSL to start systems with plain cgroup v2 support by default, you can force it by disabling cgroup v1 support in the `%USERPROFILE%/.wslconfig` file on your Windows system (create it if it doesn't exists) with the following content:

```text
[wsl2]
kernelCommandLine = cgroup_no_v1=all systemd.unified_cgroup_hierarchy=1
```
