{ config, lib, pkgs, ... }: {
  machine = "aramid";
  username = "phil";
  fullname = "Phil Thompson";
  nixfs.enable = true;

  networking.hostId = "d549b408";
  boot.kernelParams = [ "nohibernate" ];  # Hibernate not supported on ZFS (no swapfiles)
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;   # Setup a scrub schedule
  boot.zfs.forceImportRoot = false;       # Hopefully don't need backwards compatibility
  boot.zfs.devNodes = "/dev/disk/by-id";

  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_6.override {
    argsOverride = rec {
      src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
            sha256 = "sha256-VeW8vGjWZ3b8RolikfCiSES+tXgXNFqFTWXj0FX6Qj4=";
      };
      version = "6.10.14";
      modDirVersion = "6.10.14";
    };
  });

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