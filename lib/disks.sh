#!/usr/bin/env sh

boot_disk() {
  disk=$1
  local boot_size=$2

  STATE "PART" "Setup boot and primary partitions"
  SUDO "parted -s $disk -- mklabel gpt"
  SUDO "parted -s $disk -- mkpart ESP fat32 0% $boot_size"
  SUDO "parted -s $disk -- mkpart primary $boot_size 100%"
  SUDO "parted -s $disk -- set 1 boot on"
}

disk() {
  disk=$1

  STATE "PART" "Setup a disk"
  SUDO "parted -s $disk -- mklabel gpt"
  SUDO "parted -s $disk -- mkpart primary 0% 100%"
}

pool() {
  pool=$1
  local partition_num=$2
  local device=$disk$partition_num

  STATE "POOL" "Setup ZFS pool"
  RUN "cat nixfiles/secrets/password | sudo zpool create -o ashift=12 -O atime=off -O encryption=on -O keyformat=passphrase -O keylocation=prompt -O compression=lz4 -O mountpoint=none -O acltype=posixacl -O xattr=sa $pool $device"
}

dataset() {
  state=" ZFS"
  local name=$1
  local mountpoint="/mnt/$name"
  [ "$name" = "root" ] && mountpoint="/mnt"

  SUDO "zfs create -o mountpoint=legacy $pool/$name"
  SUDO "mkdir -p $mountpoint"
  SUDO "mount -t zfs $pool/$name $mountpoint"
}

partition() {
  lvm_partition=${disk}$1
  partition_name=$2
  mapper_name="/dev/mapper/$partition_name"
  partition_group=$3
  passwordfile="secrets/password"

  if [ ! -z "$passwordfile" ]; then
    SUDO "cryptsetup -q luksFormat $lvm_partition $passwordfile"
    SUDO "cryptsetup -q luksOpen $lvm_partition $partition_name -d $passwordfile"
  fi

  STATE "VOL " "Setup logical volumes"
  SUDO "pvcreate $mapper_name"
  SUDO "vgcreate $partition_group $mapper_name"
}

size() {
  SUDO "lvcreate -L $2 -n $1 $partition_group"
}

fill() {
  SUDO "lvcreate -l 100%FREE -n $1 $partition_group"
}

fat() {
  boot_partition=${disk}$1

  SUDO "mkfs.vfat -n boot $boot_partition > /dev/null"
  SUDO "mkdir -p /mnt/boot"
  SUDO "mount $boot_partition /mnt/boot"
}

ext4() {
  label=$1
  name=$2
  device="/dev/$partition_group/$name"

  SUDO "mkfs.ext4 -qFL $label $device"
  if [ "$name" = "root" ]; then
    mountpoint="/mnt"
  else
    mountpoint="/mnt/$name"
  fi
  SUDO "mkdir -p $mountpoint"
  SUDO "mount $device $mountpoint"
}

swap() {
  label=$1
  device="/dev/$partition_group/$2"
  SUDO "mkswap -qL $label $device"
  SUDO "swapon $device"
}