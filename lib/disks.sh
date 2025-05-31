#!/usr/bin/env sh

safe_mount() {
  local dev="$1"
  local target="$2"
  local type=$3
  if ! mountpoint -q "$target"; then
    [ "$type" = "zfs" ] && type="-t zfs "
    SUDO "mount $type$dev $target"
  fi
}

# Delete all Linux Boot Manager entries from EFI
# For some reason, Aramid keeps creating entries whenever a reinstall is performed
rm_boot_entries() {
  [ "$wipe" != "true" ] && return

  WAIT "Press ENTER to remove boot entries"

  efibootmgr | \
    grep "Linux Boot Manager" | \
    sed -E "s/Boot([0-9]+).*/\1/" | \
    while read num; do
    efibootmgr -Bb $num
  done
}

boot_disk() {
  [ "$wipe" != "true" ] && return

  local disk=$1
  local boot_size=$2

  WAIT "Press ENTER to repartition $disk"

  STATE "PART" "Setup boot and primary partitions"
  SUDO "sgdisk -Z $disk" # Wipe partitions
  SUDO "parted -s $disk -- mklabel gpt"
  SUDO "parted -s $disk -- mkpart ESP fat32 0% $boot_size"
  SUDO "parted -s $disk -- mkpart primary $boot_size 100%"
  SUDO "parted -s $disk -- set 1 boot on"
  SUDO "partprobe $disk"
}

data_disk() {
  [ "$wipe" = "true" ] || return

  local disk=$1

  WAIT "Press ENTER to repartition $disk"

  STATE "PART" "Setup data disk"
  SUDO "sgdisk -Z $disk" # Wipe partitions
}

# pool: <e.g. zpool>
# device: <e.g. nvme-Samsung_SSD_990_123-part2>
# encryption: <on|off>
pool() {
  pool=$1

  [ "$wipe" != "true" ] && zpool list | grep -q $pool && return

  local device=$2
  local encryption=$3
  local password=""
  local options=""

  WAIT "Press ENTER to recreate zpool '$pool'"

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
  local dataset="$pool/$name"
  local mountpoint="${root}$name"
  [ "$name" = "root" ] && mountpoint="$root"

  if ! zfs list | grep -q $dataset; then
    SUDO "zfs create -o mountpoint=legacy $dataset"
    SUDO "zfs snapshot $dataset@blank"
  else
    ECHO "$dataset exists. Skipping"
  fi

  SUDO "mkdir -p $mountpoint"
  safe_mount $dataset $mountpoint "zfs"
}

mkd() {
  local name=$1

  SUDO "mkdir -p ${root}$name"
}

fat() {
  local boot_partition=$1

  if [ "$wipe" = "true" ]; then
    WAIT "Press ENTER to format $boot_partition"
    SUDO "mkfs.vfat -n boot $boot_partition > /dev/null"
  fi

  SUDO "mkdir -p ${root}boot"
  safe_mount "$boot_partition" "${root}boot"
}