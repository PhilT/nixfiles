{ config, pkgs, ... }: {
  machine = "sapling";
  username = "phil";
  fullname = "Phil Thompson";

  boot.kernelParams = [ "nohibernate" ];  # Hibernate not supported on ZFS (no swapfiles)
  boot.zfs.enabled = true;                # Enable ZFS
  services.zfs.autoScrub.enable = true;   # Setup a scrub schedule
  security.pam.zfs.enable = true;         # Ask for encryption password on boot?
  boot.zfs.forceImportRoot = false;       # Hopefully don't need backwards compatibility

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