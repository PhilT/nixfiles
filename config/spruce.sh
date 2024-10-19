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
  boot "2G"
  boot_disk "/dev/nvme0n1"
  partition "p2" "nixos-enc" "nixos-vg"
  size "swap" "32G"
  size "nix" "200G"
  fill "root"

  ext4 "nixos" "root"
  fat
  ext4 "nix" "nix"
  swap "swap" "swap"
}

# Games drive - 2TB NTFS
# disk "nvme2n1"


create_disks() {
  disk
}
