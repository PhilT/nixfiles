aramid() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-Samsung_SSD_990_PRO_2TB_S7DNNU0X576898Y-part2"

  rm_boot_entries

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition"
  dataset "root"
  dataset "nix"
  dataset "home"
  dataset "data"

  mkd "/data/etc/ssh"
  mkd "/data/etc/NetworkManager/system-connections"
  mkd "/data/var/lib/bluetooth"

  fat "$boot_partition"
}