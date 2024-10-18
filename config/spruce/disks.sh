# Get details of current mounts with:
# lsblk -o name,fstype,size,mountpoints

# Windows drive - 1TB NTFS
# [nvme0n1]
# p1 boot partition (VFAT)
# p2 swap partition
# p3 root partition (NTFS)
# p4 recovery partition? (NTFS)

# Linux drive - 2TB ext4
# [nvme1n1]
# p1 boot partition
nvme1n1_boot = "2G"

# p2 root partition (encrypted)
nvme1n1_swap = "32G"
nvme1n1_nix = "200G"
nvme1n1_root = "100%FREE"


# Games drive - 2TB NTFS
[nvme2n1]
