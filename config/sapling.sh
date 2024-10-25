# HyperV VM - whatever I like
sapling() {
  boot_disk "/dev/nvme0n1" "2G"

  pool "zpool" "nvme-QEMU_NVMe_Ctrl_deadbeef-part2"
  dataset "root"
  dataset "nix"
  dataset "data"
  fat "/dev/nvme0n1p1"
}