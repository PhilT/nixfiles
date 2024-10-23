# Boot drive 2TB (Once upgraded)
disk() {
  boot_disk "/dev/nvme0n1" "2G"
  partition "p2" "nixos-enc" "nixos-vg"
  size "swap" "10G" # TODO: Change to 32G when I get new drive
  size "nix" "100G" # TODO: Change to 200G when I get new drive
  fill "root"

  ext4 "nixos" "root"
  fat "p1"
  ext4 "nix" "nix"
  swap "swap" "swap"
}

aramid() {
  disk
}