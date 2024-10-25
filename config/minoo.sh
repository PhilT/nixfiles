# Boot drive 256GB
disk1() {
  boot_disk "/dev/nvme0n1" "2G"
  pool "zpool" "p2"
  dataset "root"
  dataset "nix"

  fat "p1"
}

disk2() {
  disk "/dev/disk/by-id/usb-SanDisk_Extreme_55AE_32343133464E343032383531-0:0"
  #sleep 2 # Running luksFormat immediately after creating partitions
          # appears to fail. Adding a delay fixes the issue.
  pool "dpool" "-part1"
  dataset "data"
}

minoo() {
  disk1
  disk2
}