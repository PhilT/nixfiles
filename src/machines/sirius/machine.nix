{ config, pkgs, ... }: {
  machine = "sirius";
  username = "phil";
  fullname = "Phil Thompson";

  boot.initrd.luks.devices.root = {
    device = "/dev/nvme0n1p2";
    preLVM = true;
  };
}