#!/bin/bash

ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
sed -i '/#en_US.UTF-8/s/^#//' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8>/etc/locale.conf
read -p "Enter device name:" device_name
echo $device_name > /etc/hostname
cat <<EOF >> /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.0.1 ${device_name}.localdomain  $device_name
EOF

mkinitcpio -P
pacman -S --noconfirm networkmanager 
systemctl enable NetworkManager
echo "Enter root password & confirm it: "
passwd
mkdir /boot/efi
pacman -S --noconfirm grub efibootmgr 
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck
grub-mkconfig -o /boot/grub/grub.cfg
disk=$(cat /disk.txt)
efibootmgr
efibootmgr --create --disk $disk --part 1 --label "Arch Linux" --loader /efi/arch/grugx64.cfg
pacman -S --noconfirm openssh zsh
while true; do
  read -p "Execute this command for post installation activity 'bash /arch-post-installation-script.sh'" confirm
  if [[ "$confirm" == "y" || "$confirm" == "yes" ]]; then
    break
  else
    echo "confirm then exit"
    confirm=""
  fi
done
chmod +x /arch-post-installation-script.sh
bash /arch-post-installation-script.sh

