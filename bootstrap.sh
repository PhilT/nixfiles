#!/bin/sh

create_partitions() {
  [ "$partition" -eq "0" ] && return

  echo [BOOTSTRAP] Partitioning drives
  wait

  # 1 GB EFI boot partition
  # The rest will be an LVM partition

  parted -s $ssd -- mklabel gpt
  parted -s $ssd -- mkpart ESP fat32 1MB 1GB
  parted -s $ssd -- mkpart primary 1GB 100%
  parted -s $ssd -- set 1 esp on
}

setup_encryption() {
  echo [BOOTSTRAP] Setting up encryption
  wait

  cryptsetup luksFormat $lvm_partition         # Asks for an encryption password
  cryptsetup luksOpen $lvm_partition nixos-enc # Decrypt partition
  pvcreate /dev/mapper/nixos-enc               # LVM Physical volume
  vgcreate nixos-vg /dev/mapper/nixos-enc      # Volume Group
  lvcreate -L 32G -n swap nixos-vg             # Swap (logical volume)
  lvcreate -l 100%FREE -n root nixos-vg        # Root (main) filesystem (logical volume)
}

format_partitions() {
  [ "$format" -eq "0" ] && return

  echo [BOOTSTRAP] Formatting partitions
  wait

  mkfs.vfat -n boot $boot_partition
  mkfs.ext4 -F -L nixos /dev/nixos-vg/root
  mkswap -q -L swap /dev/nixos-vg/swap
  swapon /dev/nixos-vg/swap
}

mount_partitions() {
  echo [BOOTSTRAP] Mounting partitions
  wait

  mount /dev/nixos-vg/root /mnt
  mkdir -p /mnt/boot
  mount $boot_partition /mnt/boot
}

wait() {
  [ "$quiet" -eq "1" ] && return

  echo "(press enter)"
  read
}

# Check if the OS partition has been created and if so skip partitioning
partition=0
format=0
quiet=0
while getopts 'pfq' OPTION; do
  case "$OPTION" in
    p)
      partition=1
      ;;
    f)
      format=1
      ;;
    q)
      quiet=1
      ;;
  esac
done
shift $(($OPTIND - 1))

ssd=$1
password=$2

if [ -z "$ssd" ]; then
  echo "Usage: $0 [-pfq] </dev/disk> <password>" >&2
  echo "  e"
  echo "  -p Create partitions" >&2
  echo "  -f Format partitions" >&2
  echo "  -q No user input" >&2
  echo "  -d "
  echo " Example: $0 -pf /dev/nvme0n1 \$(mkpasswd)"
  exit 0
fi

boot_partition=${ssd}p1
lvm_partition=${ssd}p2

create_partitions
setup_encryption
format_partitions
mount_partitions

echo [BOOTSTRAP] Creating hardware config file
wait
nixos-generate-config --root /mnt
cp ./bootstrap.nix /mnt/etc/nixos/configuration.nix
mkdir -p /mnt/run/secrets
cp ./wireless.env /mnt/run/secrets/
sed -i "s|HASHED_PASSWORD|$password|" /mnt/etc/nixos/configuration.nix
sed -i "s|LVM_PARTITION|$lvm_partition|" /mnt/etc/nixos/configuration.nix

echo [BOOTSTRAP] Installing NixOS
wait
nixos-install 2>&1 | tee /usb/nixos-install.log

echo [BOOTSTRAP] All done.
echo '`reboot` to finish.'
