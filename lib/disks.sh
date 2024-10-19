#!/usr/bin/env sh

boot() {
  boot_size=$1
}

boot_disk() {
  disk=$1

  STATE "PART" "Setup boot disk"
  RUN "parted -s $disk -- mklabel gpt"
  RUN "parted -s $disk -- mkpart ESP fat32 0% $boot_size"
  RUN "parted -s $disk -- mkpart primary $boot_size 100%"
  RUN "parted -s $disk -- set 1 boot on"
}

disk() {
  disk=$1

  STATE "PART" "Setup a disk"
  RUN "parted -s $disk -- mklabel gpt"
  RUN "parted -s $disk -- mkpart primary 0% 100%"
}

partition() {
  lvm_partition=${disk}$1
  partition_name=$2
  mapper_name="/dev/mapper/$partition_name"
  partition_group=$3
  boot_partition=${disk}p1

  if [ ! -z "$keyfile" ]; then
    RUN "cryptsetup -q luksFormat $lvm_partition $keyfile"
    RUN "cryptsetup -q luksOpen $lvm_partition $partition_name -d $keyfile"
  fi

  STATE "VOL " "Setup logical volumes"
  RUN "pvcreate $mapper_name"
  RUN "vgcreate $partition_group $mapper_name"
}

size() {
  RUN "lvcreate -L $2 -n $1 $partition_group"
}

fill() {
  RUN "lvcreate -l 100%FREE -n $1 $partition_group"
}

fat() {
  RUN "mkfs.vfat -n boot $boot_partition > /dev/null"
  RUN "mkdir -p /mnt/boot"
  RUN "mount $boot_partition /mnt/boot"
}

ext4() {
  label=$1
  name=$2
  device="/dev/$partition_group/$name"
  RUN "mkfs.ext4 -qFL $label $device"
  if [ "$name" = "root" ]; then
    mountpoint="/mnt"
  else
    mountpoint="/mnt/$name"
  fi
  RUN "mkdir -p $mountpoint"
  RUN "mount $device $mountpoint"
}

swap() {
  label=$1
  device="/dev/$partition_group/$2"
  RUN "mkswap -qL $label $device"
  RUN "swapon $device"
}
