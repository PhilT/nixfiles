aramid() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-Samsung_SSD_990_PRO_2TB_S7DNNU0X576898Y-part2"

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition"
  dataset "root"
  dataset "nix"
  dataset "data"
  fat "$boot_partition"
}