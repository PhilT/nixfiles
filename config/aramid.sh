# Boot drive 2TB (Once upgraded)
aramid() {
  boot_disk "/dev/nvme0n1" "2G"
  pool "zpool" "p2"
  dataset "root"
  dataset "nix"
  dataset "data"

  fat "p1"
}