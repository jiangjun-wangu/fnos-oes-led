#!/bin/bash
# 一键式多硬盘LED监控服务安装脚本
# 需要以root权限运行

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
SCRIPT_NAME="multi_disk_led_monitor.sh"
SERVICE_NAME="disk-led-monitor.service"

# 校验权限
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：必须使用sudo运行此脚本" >&2
    exit 1
fi

# 创建主脚本
cat > "$INSTALL_DIR/$SCRIPT_NAME" << 'EOF'
#!/bin/bash
# 适配green:disk系列LED的多硬盘监控脚本
declare -A DISK_LED_MAP=(
    ["sda"]="green:disk"      # sda → 绿色主盘灯
    ["sdb"]="green:disk_1"    # sdb → 绿色盘灯1
    ["sdc"]="green:disk_2"    # sdc → 绿色盘灯2
)
CHECK_INTERVAL=1

init_leds() {
    for led in "${DISK_LED_MAP[@]}"; do
        if [ -d "/sys/class/leds/$led" ]; then
            echo none > "/sys/class/leds/$led/trigger"
            echo 0 > "/sys/class/leds/$led/brightness"
        else
            echo "WARNING: LED $led not found!" >&2
        fi
    done
}

check_disk_activity() {
    local disk=$1
    local led=${DISK_LED_MAP[$disk]}
    read_ios=$(awk '{print $1}' "/sys/block/$disk/stat" 2>/dev/null)
    write_ios=$(awk '{print $9}' "/sys/block/$disk/stat" 2>/dev/null)
    if [[ "$read_ios" -gt 0 || "$write_ios" -gt 0 ]]; then
        echo 1 > "/sys/class/leds/$led/brightness"
    else
        echo 0 > "/sys/class/leds/$led/brightness"
    fi
}

main_loop() {
    while true; do
        for disk in "${!DISK_LED_MAP[@]}"; do
            [ -e "/sys/block/$disk" ] && check_disk_activity "$disk" &
        done
        wait
        sleep "$CHECK_INTERVAL"
    done
}

init_leds
main_loop
EOF

# 创建systemd服务
cat > "$SERVICE_DIR/$SERVICE_NAME" << EOF
[Unit]
Description=Multi-Disk LED Activity Monitor
After=sysinit.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/$SCRIPT_NAME
ExecStopPost=/bin/bash -c 'for led in /sys/class/leds/green:disk*; do echo 0 > "\$led/brightness"; done'
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# 设置权限和安装服务
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
systemctl daemon-reload
systemctl enable --now "$SERVICE_NAME"

# 验证安装状态
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo -e "\n✅ 安装成功！服务状态："
    systemctl status "$SERVICE_NAME" --no-pager -l
else
    echo -e "\n❌ 安装失败！请检查日志："
    journalctl -u "$SERVICE_NAME" --since "5 min ago"
    exit 1
fi