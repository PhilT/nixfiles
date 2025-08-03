{ config, pkgs, ... }: {
  machine = "seedling";
  username = "phil";
  fullname = "Phil Thompson";
  swayOptions = "--unsupported-gpu";

  networking.hostId = "c3a88d59";

  # Hibernate not supported on ZFS (no swapfiles)
  # but this is a VM so we can create snapshots with Qemu
  boot.blacklistedKernelModules = [ "efifb" "vesafb" "nouveau" ];
  boot.kernelParams = [
    "nohibernate"
    "video=efifb:off"
    "video=vesafb:off"
    "nomodeset"  # optional fallback to disable generic modesetting
  ];

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