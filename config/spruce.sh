# Get details of current mounts with:
# lsblk -f

# Windows drive - 1TB NTFS
# boot_disk "nvme0n1"
# p1 boot partition (VFAT)
# p2 swap partition
# p3 root partition (NTFS)
# p4 recovery partition? (NTFS)

# Linux drive - 2TB ext4
disk() {
  boot_disk "/dev/nvme2n1" "2G"
  partition "p2" "nixos-enc" "nixos-vg"
  size "swap" "32G"
  size "nix" "200G"
  fill "root"

  ext4 "nixos" "root"
  fat "p1"
  ext4 "nix" "nix"
  swap "swap" "swap"
}

# Games drive - 2TB NTFS
# disk "nvme2n1"


spruce() {
  disk
}