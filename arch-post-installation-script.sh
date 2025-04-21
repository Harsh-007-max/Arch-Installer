#!/bin/bash
read -p "Enter username: " user_name
useradd -m -G wheel -s /bin/zsh "$user_name"
echo "Enter password for $user_name and confirm the password."
passwd "$user_name"
sed -i '/# %wheel ALL=(ALL:ALL) ALL/s/^#//' "/etc/sudoers"


