# patch —— 镜像定制叠加层

本目录收录我们对上游 archlinux-wsl 的全部定制。

**上游文件在仓库里保持原样**，`scripts/`、`rootfs/`、`Makefile` 等都能与上游逐字节对齐；
所有定制都通过 `patch/apply.sh` 在构建时叠加到工作副本上。

## 用法

```bash
bash patch/apply.sh          # 叠加定制（幂等，可重复执行）
make build IMAGE_VERSION=YYYY.MM.DD
```

`apply.sh` 做两件事：

1. 在 `scripts/build-image.sh` 的 `systemd-sysusers` 之后插入一行，调用 `scripts/customize-image.sh`。
   锚点是 `/usr/bin/systemd-sysusers --root "/"`，必须在这个位置**之后**：
   `useradd -G wheel` 依赖 wheel 组，而该组由 `/usr/lib/sysusers.d/basic.conf` 定义、
   在 sysusers 执行时才创建，插早了会直接失败（`group 'wheel' does not exist`）。
   找不到锚点会报错退出——不会静默产出一个定制没生效的镜像。
2. 把 `patch/rootfs/` 覆盖到 `rootfs/`，并放置 `customize-image.sh`

## 内容

| 路径 | 作用 |
| --- | --- |
| `apply.sh` | 叠加入口，幂等 |
| `customize-image.sh` | 构建期定制：追加软件包、中文字体、locale、默认用户、fontconfig 断链修复 |

### `rootfs/` 下的静态文件

`patch/rootfs/` 会整体覆盖到仓库的 `rootfs/`。其中 **3 个是替换上游同名文件**
（它们本来就是上游 `rootfs/` 的一部分，只能整体覆盖），**5 个是新增**的
（上游 `rootfs/` 里没有对应文件）。

| 路径 | 替换/新增 | 内容 |
| --- | --- | --- |
| `rootfs/etc/wsl.conf` | **替换** | 在上游原有 `[boot] systemd=true` 之外追加 `[user] default=arch` |
| `rootfs/etc/locale.conf` | **替换** | `LANG=zh_CN.UTF-8`（上游是 `C.UTF-8`） |
| `rootfs/etc/pacman.d/mirrorlist` | **替换** | 中科大 + 清华（上游是 fastly + geo） |
| `rootfs/etc/sudoers.d/wheel` | **新增** | wheel 组免密 sudo |
| `rootfs/etc/profile.d/fcitx5.sh` | **新增** | 输入法环境变量与登录自启 |
| `rootfs/etc/profile.d/d3d12.sh` | **新增** | WSLg 走 D3D12 硬件加速 |
| `rootfs/etc/skel/.config/fcitx5/profile` | **新增** | 预置拼音输入法 |
| `rootfs/etc/fonts/local.conf` | **新增** | 界面字体 Sarasa UI SC，等宽字体 Maple Mono |

上游 `rootfs/` 的另外两个文件未被改动，也不会被覆盖：
`rootfs/etc/wsl-distribution.conf`、`rootfs/usr/lib/wsl/`（图标与首次启动脚本）。

## 需要注意

- 上游若改动了 `build-image.sh` 里那行 `--hookdir ... base`，`apply.sh` 会报错停下，
  此时需要更新锚点。
- `customize-image.sh` 顶部集中了可配置项：追加软件包列表、字体 URL 与 sha256、用户名。
  字体版本换新时改那几个常量即可，sha256 也要同步更新。
- `customize-image.sh` 里跳过了 `qt6-webengine`（fcitx5-chinese-addons 的强制依赖，
  连带 421 MiB 的 Qt 与 ffmpeg 依赖树）。这个假设不会写进 pacman 数据库，
  所以日后 `fcitx5-chinese-addons` 升级时会被装回来；要长期避免需在 `pacman.conf`
  里 `IgnorePkg` 掉该包。
