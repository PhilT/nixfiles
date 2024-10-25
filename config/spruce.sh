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
  boot_disk "/dev/nvme2n1" "2G"
  pool "zpool" "p2"
  dataset "root"
  dataset "nix"
  dataset "data"

  fat "p1"
}

# Games drive - 2TB NTFS
# disk "nvme2n1"
