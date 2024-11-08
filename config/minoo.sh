# Boot drive 256GB
minoo_disk1() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-Lexar_SSD_NM620_256GB_PDB545R000033P1109-part2"

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition"
  dataset "root"
  dataset "nix"
  fat "$boot_partition"
}

# Data drive 2TB
minoo_disk2() {
  local disk="usb-SanDisk_Extreme_55AE_32343133464E343032383531-0:0"

  data_disk "/dev/disk/by-id/$disk"
  pool "dpool" "$disk"
  dataset "data"
}

minoo() {
  minoo_disk1
  minoo_disk2
}

minoo_use_keyfile() {
  local keyfile="/root/.dpool.key"
  generate_key $keyfile

  change_key "dpool" $keyfile
}