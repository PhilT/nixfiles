keyfile=secrets/luks.key

# Boot drive 256GB
disk1() {
  boot "2G"
  boot_disk "/dev/nvme0n1"
  partition "p2" "nixos-enc" "nixos-vg"
  size "swap" "10G"
  size "nix" "100G"
  fill "root"

  ext4 "nixos" "root"
  fat
  ext4 "nix" "nix"
  swap "swap" "swap"
}

disk2() {
  disk "/dev/disk/by-id/usb-SanDisk_Extreme_55AE_32343133464E343032383531-0:0"
  sleep 2 # Running luksFormat immediately after creating partitions
          # appears to fail. Adding a delay fixes the issue.
  partition "-part1" "nixos-enc2" "nixos-vg2"
  fill "data"
  ext4 "data" "data"

  RUN "cp secrets/luks.key"
}

create_disks() {
  disk1
  disk2
}