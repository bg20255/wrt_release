#!/bin/sh
# 固件首次启动时自动配置 OAF（appfilter）

# 1. 确保 OAF 服务配置存在（防止未安装的情况报错）
if [ -f "/etc/config/appfilter" ] && [ -x "/etc/init.d/appfilter" ]; then
    # 2. 设置 OAF 核心启用（uci 配置，对应 LuCI 中的“启用”开关）
    uci set appfilter.global.enable='1'
    # 3. 启用 OAF 服务开机自启（对应 LuCI 启动项中的“已启用”）
    /etc/init.d/appfilter enable
    # 4. 立即启动 OAF 服务（对应 LuCI 中的“启动”按钮）
    /etc/init.d/appfilter start
    # 5. 提交 uci 配置（保存修改）
    uci commit appfilter
    echo "OAF (appfilter) enabled and started successfully."
else
    echo "OAF (appfilter) not found, skip configuration."
fi
