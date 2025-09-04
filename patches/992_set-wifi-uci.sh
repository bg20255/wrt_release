#!/bin/sh

# 1. 获取当前设备型号（board_name，如 jdcloud,ax1800-pro 或 jdcloud,re-ss-01）
board_name=$(cat /tmp/sysinfo/board_name)

# 2. 核心 WiFi 配置函数（输入参数：radio编号、信道、htmode、发射功率、SSID、密码）
configure_wifi() {
    local radio=$1          # WiFi 射频编号（0=5G, 1=2.4G）
    local channel=$2        # WiFi 信道（需与频段匹配）
    local htmode=$3         # WiFi 模式（HE80=5G WiFi6 80MHz，HE40=2.4G WiFi6 40MHz）
    local txpower=$4        # 发射功率（auto=默认，dBm=手动值，受硬件限制）
    local ssid=$5           # WiFi 名称
    local key=$6            # WiFi 密码（至少8位）
    
    # 检查当前 WiFi 是否已有加密配置，有则跳过（避免重复修改）
    local now_encryption=$(uci get wireless.default_radio${radio}.encryption 2>/dev/null)
    if [ -n "$now_encryption" ] && [ "$now_encryption" != "none" ]; then
        return 0
    fi
    
    # 用 uci 命令批量设置 WiFi 参数（# 开头为注释，不会执行）
    uci -q batch <<EOF
set wireless.radio${radio}.channel="${channel}"          # 设置信道
set wireless.radio${radio}.htmode="${htmode}"            # 设置 WiFi 模式（带宽）
set wireless.radio${radio}.mu_beamformer='1'             # 启用多用户波束成形
set wireless.radio${radio}.country='CN'                  # 国家码（符合国内法规）
set wireless.radio${radio}.txpower="${txpower}"          # 发射功率（auto=默认）
set wireless.radio${radio}.cell_density='0'              # 小区密度（默认值）
set wireless.radio${radio}.disabled='0'                  # 启用该射频（0=启用）

# 仅 2.4G（radio=1）时，添加 noscan=1（强制 40MHz 不回退）
$( [ "${radio}" -eq 1 ] && echo "set wireless.radio${radio}.noscan='1'" )

set wireless.default_radio${radio}.ssid="${ssid}"        # 设置 WiFi 名称
set wireless.default_radio${radio}.encryption='psk2+ccmp'# 加密方式（WPA2+AES，安全）
set wireless.default_radio${radio}.key="${key}"          # 设置 WiFi 密码
set wireless.default_radio${radio}.ieee80211k='1'        # 启用 802.11k（辅助信道切换）
set wireless.default_radio${radio}.time_advertisement='2'# 启用时间广播
set wireless.default_radio${radio}.time_zone='CST-8'     # 时区（中国标准时间）
set wireless.default_radio${radio}.bss_transition='1'    # 启用 BSS 切换（无缝漫游）
set wireless.default_radio${radio}.wnm_sleep_mode='1'    # 启用 WiFi 休眠（降功耗）
set wireless.default_radio${radio}.wnm_sleep_mode_no_keys='1' # 休眠无需重验密钥
EOF
}

# 3. ax1800pro 专属配置（2个射频：0=5G，1=2.4G）
jdc_ax1800_pro_wifi_cfg() {
    # 配置 5G WiFi（radio0）：信道149，WiFi6 80MHz，功率默认，SSID=JDC_5G，密码1234567890
    configure_wifi 0 149 HE80 auto 'JDC_5G' '1234567890'
    # 配置 2.4G WiFi（radio1）：信道1，WiFi6 40MHz，功率默认，SSID=JDC，密码1234567890
    configure_wifi 1 1 HE40 auto 'JDC' '1234567890'
}

# 4. 只执行 ax1800pro 的配置（其他设备不处理）
case "${board_name}" in
jdcloud,ax1800-pro | \
jdcloud,re-ss-01)
    jdc_ax1800_pro_wifi_cfg  # 执行 ax1800pro 的 WiFi 配置
    ;;
*)
    exit 0  # 不是 ax1800pro，直接退出
    ;;
esac

# 5. 保存配置并重启网络（使修改生效）
uci commit wireless
/etc/init.d/network restart
