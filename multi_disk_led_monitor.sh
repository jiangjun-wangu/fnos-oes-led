#!/bin/bash
# 适配green:disk系列LED的多硬盘监控脚本
# 配置参数
declare -A DISK_LED_MAP=(
    ["sda"]="green:disk"      # sda → 绿色主盘灯
    ["sdb"]="green:disk_1"    # sdb → 绿色盘灯1
    ["sdc"]="green:disk_2"    # sdc → 绿色盘灯2
    # 根据实际硬盘添加更多映射
)
CHECK_INTERVAL=1  # 检测间隔（秒）

# 初始化所有LED
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

# 检查单个硬盘活动
check_disk_activity() {
    local disk=$1
    local led=${DISK_LED_MAP[$disk]}
    
    # 读取硬盘统计信息
    read_ios=$(awk '{print $1}' "/sys/block/$disk/stat" 2>/dev/null)
    write_ios=$(awk '{print $9}' "/sys/block/$disk/stat" 2>/dev/null)
    
    # 控制LED状态
    if [[ "$read_ios" -gt 0 || "$write_ios" -gt 0 ]]; then
        echo 1 > "/sys/class/leds/$led/brightness"  # 亮绿灯
    else
        echo 0 > "/sys/class/leds/$led/brightness"  # 灭灯
    fi
}

# 主监控循环
main_loop() {
    while true; do
        for disk in "${!DISK_LED_MAP[@]}"; do
            if [ -e "/sys/block/$disk" ]; then
                check_disk_activity "$disk" &  # 并行检查
            fi
        done
        wait
        sleep "$CHECK_INTERVAL"
    done
}

# 执行流程
init_leds
main_loop