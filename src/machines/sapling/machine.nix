{ config, pkgs, ... }: {
  networking.hostId = "c3a88d59";
  machine = "sapling";
  username = "phil";
  fullname = "Phil Thompson";

  boot.initrd.kernelModules = [ "hv_vmbus" "hv_storvsc" ]; # Needed for HyperV
  boot.kernelParams = [ "nohibernate" ];  # Hibernate not supported on ZFS (no swapfiles)
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
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };
}