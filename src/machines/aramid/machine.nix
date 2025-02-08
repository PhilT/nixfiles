{ config, lib, pkgs, ... }: {
  machine = "aramid";
  username = "phil";
  fullname = "Phil Thompson";
  etcDir = "${config.dataDir}/etc";
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

    "/home" = {
      device = "zpool/home";
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

  # Ephemeral OS
  # TODO: Move to more general location once the rest
  # of my machines are using it
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r zpool/root@blank
  '';

  etc."NetworkManager/system-connections" = {
    source = "/data/etc/NetworkManager/system-connections/";
  };

  systemd.tmpfiles.rules = [
    "L /var/lib/bluetooth - - - - /data/var/lib/bluetooth"
  ];
  # End of Ephemeral OS
}