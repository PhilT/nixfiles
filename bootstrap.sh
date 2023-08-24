#!/bin/sh

create_partitions() {
  [ "$partition" -eq "0" ] && return

  echo [BOOTSTRAP] Partitioning drives
  wait

  parted -s $ssd -- mklabel gpt
  parted -s $ssd -- mkpart primary 512MB -8GB
  parted -s $ssd -- mkpart primary linux-swap -8GB 100%
  parted -s $ssd -- mkpart ESP fat32 1MB 512MB
  parted -s $ssd -- set 3 esp on
}

format_partitions() {
  [ "$format" -eq "0" ] && return

  echo [BOOTSTRAP] Formatting partitions
  wait

  mkfs.ext4 -F -L nixos $nixos_partition
  mount /dev/disk/by-label/nixos /mnt

  mkswap -q -L swap $swap_partition
  swapon $swap_partition

  mkfs.fat -F 32 -n boot $boot_partition
  mkdir -p /mnt/boot
  mount /dev/disk/by-label/boot /mnt/boot
}

wait() {
  [ "$quiet" -eq "1" ] && return

  echo Press ENTER to continue
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

nixos_partition=${ssd}p1
swap_partition=${ssd}p2
boot_partition=${ssd}p3

create_partitions

format_partitions

echo [BOOTSTRAP] Creating hardware config file
wait
nixos-generate-config --root /mnt
cp ./bootstrap.nix /mnt/etc/nixos/configuration.nix
sed -i "s!HASHED_PASSWORD!$password!" /mnt/etc/nixos/configuration.nix

echo [BOOTSTRAP] Installing NixOS
wait
nixos-install 2>&1 | tee /usb/nixos-install.log

echo [BOOTSTRAP] All done.
echo '`reboot` to finish.'
