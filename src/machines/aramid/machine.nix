{ config, lib, pkgs, ... }: {
  machine = "aramid";
  username = "phil";
  fullname = "Phil Thompson";
  persistedHomeDir = "${config.dataDir}/home";
  etcDir = "${config.dataDir}/etc";
  varDir = "${config.dataDir}/var";
  nixfs.enable = true;

  networking.hostId = "d549b408";
  boot.kernelParams = [
    "nohibernate"         # Hibernate not supported on ZFS (no swapfiles)
  ];
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;   # Setup a scrub schedule
  boot.zfs.forceImportRoot = false;       # Hopefully don't need backwards compatibility
  boot.zfs.devNodes = "/dev/disk/by-id";

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