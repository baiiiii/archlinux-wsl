#!/bin/bash
# fcitx5 输入法环境变量：告诉各类 GUI 工具包走哪个输入法框架
export LC_CTYPE=zh_CN.UTF-8
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
export GLFW_IM_MODULE=ibus

# WSLg 里没有桌面环境，fcitx5 自带的 XDG autostart 不会被触发，
# 所以在这里补一个自启：仅限交互式 shell，且图形环境已就绪时
case $- in
    *i*) ;;
    *) return 0 ;;
esac

# WSLg 的 weston 拒绝客户端绑定 zwp_input_method_v1（返回 permission denied），
# fcitx5 连上的 Wayland 连接会被合成器强制断开，进程随即退出。
# 这里清空 WAYLAND_DISPLAY 让它退回 X11/XWayland；GTK/Qt 前端应用
# 仍通过 D-Bus immodule 与它通信，不受影响。
if [[ -n "${DISPLAY:-}" ]] && ! pgrep -x fcitx5 >/dev/null 2>&1; then
    # 重定向的目标目录缺失会让整条命令直接不执行（只在登录时一闪而过地报个错），
    # 所以先建好 ~/.cache
    mkdir -p "${HOME}/.cache"
    WAYLAND_DISPLAY= fcitx5 -d >>"${HOME}/.cache/fcitx5-autostart.log" 2>&1 &
    # 从作业表里摘掉：fcitx5 -d 会立刻 daemonize（父进程马上退出），
    # 不摘的话每次登录 bash 都会打印一行 "[1]+ 已完成 ..." 的作业通知
    disown 2>/dev/null || true
fi
