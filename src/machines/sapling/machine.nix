{ config, pkgs, ... }: {
  machine = "sapling";
  username = "phil";
  fullname = "Phil Thompson";
  vulkan.enable = false;

  networking.hostId = "c3a88d59";
  boot.kernelParams = [ "nohibernate" ];  # Hibernate not supported on ZFS (no swapfiles)
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;   # Setup a scrub schedule
  boot.zfs.forceImportRoot = false;       # Hopefully don't need backwards compatibility
  boot.zfs.devNodes = "/dev/disk/by-id";
  services.qemuGuest.enable = true;

  fileSystems = {
    "/" = {
      device = "zpool/root";
      fsType = "zfs";
    };

    "/nix" = {
      device = "zpool/nix";
      fsType = "zfs";
    };

    "/data" = {
      device = "zpool/data";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" "defaults" ];
    };
  };
}