#!/bin/bash

sudo systemctl stop snapd
sudo systemctl disable snapd

for snap in $(snap list | awk 'NR>1 {print $1}'); do
  sudo snap remove "$snap"
done

sudo apt purge snapd -y
sudo rm -rf /var/cache/snapd/ /snap

sudo umount /snap 2>/dev/null

sudo systemctl mask snapd

sudo apt purge gnome-software-plugin-snap -y
sudo apt --fix-broken install -y && sudo apt autoremove -y && sudo apt autoclean -y
