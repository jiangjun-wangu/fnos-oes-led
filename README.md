飞牛fnos系统刷写wxy-oes设备硬盘灯状态：
1.插入硬盘有读取或写入为绿灯，否则灯灭。
install-led.sh为一键安装脚本：
其他为分开部署脚本二选一。
备注：
disk-led-monitor.service为文件
multi_disk_led_monitor.sh 控制程序
部署步骤
创建脚本文件
bash
sudo nano /usr/local/bin/multi_disk_led_monitor.sh
粘贴脚本内容后保存，设置权限：

bash
sudo chmod +x /usr/local/bin/multi_disk_led_monitor.sh
创建Systemd服务
bash
sudo nano /etc/systemd/system/disk-led-monitor.service
粘贴服务配置后保存。

启用并启动服务
bash
sudo systemctl daemon-reload
sudo systemctl enable disk-led-monitor.service
sudo systemctl start disk-led-monitor.service
验证命令
bash
# 查看硬盘活动
watch -n1 "cat /sys/block/sda/stat | awk '{print \$1,\$9}'"

# 手动测试LED控制
echo 1 > /sys/class/leds/green:disk/brightness  # 亮主盘灯
echo 0 > /sys/class/leds/green:disk/brightness  # 灭主盘灯
