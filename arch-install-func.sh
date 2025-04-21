#!/bin/bash
check_for_drive_exist(){
  local drive_name=$1
  if [[ -e "$drive_name" ]]; then
    return 0
  else
    return 1
  fi
}
else_repeat_drive_question(){
  clear
  lsblk
  read -p "Select a disk to partition: " disk_name
  read -p "Are you sure you want to partiton $disk_name (Y/n): " disk_name_confirm
  echo "$disk_name $disk_name_confirm"
}
post_mount_chroot(){
  disk=$1

  if ! pacstrap -K /mnt base base-devel linux linux-firmware vim vifm -y; then
    echo "Error: Failed to install base system. i.e. packstrap error"
    exit 1
  fi
  if ! genfstab -U /mnt /mnt/etc/fstab; then
    echo "Error: Failed to generate fstab. i.e. genfstab error"
    exit 1
  fi
  cp ./arch-chroot-script.sh /mnt/arch-chroot-script.sh
  cp ./arch-post-installation-script.sh /mnt/arch-post-installation-script.sh
  echo "$disk" > /mnt/disk.txt
  arch-chroot /mnt /bin/bash -c  "chmod +x /arch-chroot-script.sh && /arch-chroot-script.sh"
}
mount_partitions(){
  local disk=$1
  mount --mkdir "${disk}p3" /mnt       
  mount --mkdir "${disk}p1" /mnt/boot  
  mkdir /mnt/boot/efi
  post_mount_chroot "$disk"
}
partitioner(){

  boot=$1
  swap=$2
  root=$3
  home=$4
  disk=$5

  parted -s "$disk" unit MiB\
    mklabel gpt \
    mkpart primary fat32 1MiB ${boot}MiB \
    mkpart primary linux-swap ${boot}MiB ${swap}MiB \
    mkpart primary ext4 ${swap}MiB ${root}MiB \
    mkpart primary ext4 ${root}MiB ${home}MIB \
    set 1 esp on \
    set 2 swap on
  return_code=$?
  echo "partitition disk return code: $return_code"

  mkfs.fat -F32 "${disk}p1"
  mkswap "${disk}p2"
  swapon "${disk}p2"
  mkfs.ext4 "${disk}p3"
  mkfs.ext4 "${disk}p4"
  mount_partitions $disk 

}
partition_drive(){
  selected_drive=$1
  echo "Paritiion the drive: $selected_drive"
  echo "MiB=G x 1024"
  read -p "Enter size of EFI boot partition in MiB: " efi_partition_size
  read -p "Enter size of swap partition in MiB: " swap_partition_size
  read -p "Enter size of root partition in MiB: " root_partition_size
  read -p "Enter size of home partition in MiB: " home_partition_size
  partitioner $efi_partition_size $swap_partition_size $root_partition_size $home_partition_size $selected_drive
}
select_drive(){
  lsblk
  read -p "Select a disk to partition: " disk_name
  while true; do
    read -p "Are you sure you want to partiton $disk_name (Y/n): " disk_name_confirm
    if [[ "$disk_name_confirm" == "yes" || "$disk_name_confirm" == "y" ]]; then
      if check_for_drive_exist "$disk_name"; then
        partition_drive "$disk_name"
        break
      else
        echo "disk $disk_name does not exist or is not a valid name enter valid disk name."
        result=$(else_repeat_drive_question)
        disk_name=$(echo "$result" | awk '{print $1}')
        disk_name_confirm=$(echo "$result" | awk '{print $2}')
      fi
    else
      result=$(else_repeat_drive_question)
      disk_name=$(echo "$result" | awk '{print $1}')
      disk_name_confirm=$(echo "$result" | awk '{print $2}')
    fi
  done
}
