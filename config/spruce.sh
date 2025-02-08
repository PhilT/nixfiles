# Get details of current mounts with:
# lsblk -f

# Windows drive - 1TB NTFS
# boot_disk "nvme0n1"
# p1 boot partition (VFAT)
# p2 swap partition
# p3 root partition (NTFS)
# p4 recovery partition? (NTFS)

# Linux drive - 2TB ext4
spruce() {
  local disk="/dev/nvme0n1"
  local boot_partition="${disk}p1"
  local primary_partition="nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA26792J-part2"

  rm_boot_entries

  boot_disk "$disk" "2G"

  pool "zpool" "$primary_partition"
  dataset "root"
  dataset "nix"
  dataset "home"
  dataset "data"

  fat "$boot_partition"
}

# Games drive - 2TB NTFS
# disk "nvme2n1"