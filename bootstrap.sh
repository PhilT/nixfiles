#!/bin/sh

source ./common.env
lvm_partition=${ssd}p2

setup_wifi() {
  echo [BOOTSTRAP] Connecting Wifi

  wpa_passphrase $ssid $psk > /etc/wpa_supplicant.conf
  systemctl restart wpa_supplicant.service
}

check_wifi() {
  while ! ping -c 1 google.com > /dev/null 2>&1; do
    sleep 3
  done

  echo [BOOTSTRAP] Wifi connected
}

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

decrypt_drive() {
  cryptsetup luksOpen $lvm_partition nixos-enc # Decrypt partition
}

setup_encryption() {
  [ "$partition" -eq "0" ] && return

  echo [BOOTSTRAP] Setting up encryption
  wait

  cryptsetup luksFormat $lvm_partition         # Asks for an encryption password
  decrypt_drive
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

generate_config() {
  echo [BOOTSTRAP] Creating hardware config file
  wait

  nixos-generate-config --root /mnt
  cp ./bootstrap.nix /mnt/etc/nixos/configuration.nix
  ./replace_vars.sh $machine /mnt/etc/nixos/configuration.nix
}

install_nixos() {
  echo [BOOTSTRAP] Installing NixOS
  wait

  nixos-install --no-root-password 2>&1 | tee /usb/nixos-install.log
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

machine=$1

if [ -z "$ssd" ]; then
  echo "Usage: $0 [-pfq] </dev/disk>" >&2
  echo "  -p Create partitions" >&2
  echo "  -f Format partitions" >&2
  echo "  -q No user input" >&2
  echo " Example: $0 -pf <darko|spruce>" >&2
  exit 0
fi

boot_partition=${ssd}p1
lvm_partition=${ssd}p2

setup_wifi
create_partitions
setup_encryption
format_partitions
[ "$partition" -eq "0" ] && decrypt_drive # If we've not already decrypted the drive
mount_partitions
generate_config
check_wifi
install_nixos

echo [BOOTSTRAP] All done.
echo '`reboot` to finish!'
