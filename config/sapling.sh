# HyperV VM - whatever I like
sapling() {
  boot_disk "/dev/vda" "2G"
  pool "zpool" "2"
  dataset "root"
  dataset "nix"
  dataset "data"
  fat "1"
}