# HyperV VM - whatever I like
sapling() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-QEMU_NVMe_Ctrl_deadbeef-part2"

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition"
  dataset "root"
  dataset "nix"
  dataset "data"
  fat "$boot_partition"
}