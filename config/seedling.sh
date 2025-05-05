# Qemu VM - whatever I like
seedling() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-QEMU_NVMe_Ctrl_deadbeee-part2"

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition" "off"
  dataset "root"
  dataset "nix"
  dataset "home"
  dataset "data"

  mkd "/data/etc/ssh"
  mkd "/data/etc/NetworkManager/system-connections"
  mkd "/data/var/lib/bluetooth"

  fat "$boot_partition"
}