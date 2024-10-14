#!/bin/bash

# 停止并禁用 snapd
sudo systemctl stop snapd
sudo systemctl disable snapd

# 删除所有已安装的 Snap 包
for snap in $(snap list | awk 'NR>1 {print $1}'); do
  sudo snap remove "$snap"
done

# 移除 snapd 及其相关目录
sudo apt purge snapd -y
sudo rm -rf /var/cache/snapd/ /snap

# 卸载 /snap 挂载点
sudo umount /snap 2>/dev/null

# 屏蔽 snapd 防止其重新安装
sudo systemctl mask snapd

# 移除 GNOME Snap 插件（如果存在）
sudo apt purge gnome-software-plugin-snap -y
sudo apt --fix-broken install -y && sudo apt autoremove -y && sudo apt autoclean -y
