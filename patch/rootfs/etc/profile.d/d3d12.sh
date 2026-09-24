#!/bin/bash
# WSLg GPU 加速：让 OpenGL / VA-API 走 D3D12 直通而不是软件渲染
# 光装 mesa / vulkan-dzn 还不够，应用需要这两个变量才会选 d3d12 驱动，
# 否则会静默回退到 llvmpipe 软件渲染（可用 glxinfo -B 看 renderer 确认）
export GALLIUM_DRIVER=d3d12
export LIBVA_DRIVER_NAME=d3d12
