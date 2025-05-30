#!/usr/bin/env sh

# Delete all Linux Boot Manager entries from EFI
# For some reason, Aramid keeps creating entries whenever a reinstall is performed
rm_boot_entries() {
  efibootmgr | grep "Linux Boot Manager" | sed -E "s/Boot([0-9]+).*/\1/" | while read num; do
    efibootmgr -Bb $num
  done
}

boot_disk() {
  local disk=$1
  local boot_size=$2

  STATE "PART" "Setup boot and primary partitions"
  SUDO "sgdisk -Z $disk" # Wipe partitions
  SUDO "parted -s $disk -- mklabel gpt"
  SUDO "parted -s $disk -- mkpart ESP fat32 0% $boot_size"
  SUDO "parted -s $disk -- mkpart primary $boot_size 100%"
  SUDO "parted -s $disk -- set 1 boot on"
  SUDO "partprobe $disk"
}

data_disk() {
  local disk=$1

  STATE "PART" "Setup data disk"
  SUDO "sgdisk -Z $disk" # Wipe partitions
}

# pool: <e.g. zpool>
# device: <e.g. nvme-Samsung_SSD_990_123-part2>
# encryption: <on|off>
pool() {
  pool=$1
  local device=$2
  local encryption=$3
  local password=""
  local options=""

  if [ "$encryption" = "on" ]; then
    password="echo $passwd | "
    options=" \
      -O encryption=on \
      -O keyformat=passphrase \
      -O keylocation=prompt"
  fi

  STATE "POOL" "Setup ZFS pool"
  RUN " \
    $password \
    sudo zpool create -f \
    $options \
    -o ashift=12 \
    -O atime=off \
    -O compression=lz4 \
    -O mountpoint=none \
    -O acltype=posixacl \
    -O xattr=sa \
    $pool \
    $device"
}

# Create a ZFS dataset and snapshot it in it's empty state
# to be able to rollback for ephemeral storage.
dataset() {
  state=" ZFS"
  local name=$1
  local mountpoint="/mnt/$name"
  [ "$name" = "root" ] && mountpoint="/mnt"

  SUDO "zfs create -o mountpoint=legacy $pool/$name"
  SUDO "zfs snapshot $pool/$name@blank"
  SUDO "mkdir -p $mountpoint"
  SUDO "mount -t zfs $pool/$name $mountpoint"
}

mkd() {
  local name=$1

  SUDO "mkdir -p /mnt$name"
}

fat() {
  local boot_partition=$1

  SUDO "mkfs.vfat -n boot $boot_partition > /dev/null"
  SUDO "mkdir -p /mnt/boot"
  SUDO "mount $boot_partition /mnt/boot"
}