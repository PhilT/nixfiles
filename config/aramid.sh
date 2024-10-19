# Boot drive 2TB (Once upgraded)
disk() {
  boot "2G"
  boot_disk "/dev/nvme0n1"
  partition "p2" "nixos-enc" "nixos-vg"
  size "swap" "10G" # TODO: Change to 32G when I get new drive
  size "nix" "100G" # TODO: Change to 200G when I get new drive
  fill "root"

  ext4 "nixos" "root"
  fat
  ext4 "nix" "nix"
  swap "swap" "swap"
}

create_disks() {
  disk
}