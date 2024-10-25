#!/usr/bin/env sh

boot_disk() {
  disk=$1
  local boot_size=$2

  STATE "PART" "Setup boot and primary partitions"
  SUDO "parted -s $disk -- mklabel gpt"
  SUDO "parted -s $disk -- mkpart ESP fat32 0% $boot_size"
  SUDO "parted -s $disk -- mkpart primary $boot_size 100%"
  SUDO "parted -s $disk -- set 1 boot on"
  SUDO "partprobe $disk"
}

pool() {
  pool=$1
  local device=$2

  STATE "POOL" "Setup ZFS pool"
  RUN "echo $passwd | sudo zpool create -o ashift=12 -O atime=off -O encryption=on -O keyformat=passphrase -O keylocation=prompt -O compression=lz4 -O mountpoint=none -O acltype=posixacl -O xattr=sa $pool $device"
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

fat() {
  boot_partition=$1

  SUDO "mkfs.vfat -n boot $boot_partition > /dev/null"
  SUDO "mkdir -p /mnt/boot"
  SUDO "mount $boot_partition /mnt/boot"
}