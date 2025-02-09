{ config, lib, pkgs, ... }: {
  machine = "aramid";
  username = "phil";
  fullname = "Phil Thompson";
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

    # TODO: Enable once we're happy to have it removed on boot
    # "/home" = {
    #   device = "zpool/home";
    #   fsType = "zfs";
    # };

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

  # Ephemeral OS
  # TODO: Move to more general location once the rest
  # of my machines are using it
  # boot.initrd.systemd.services.initrd-rollback-root = {
  #   after = [ "zfs-import-rpool.service" ];
  #   before = [ "sysroot.mount" "local-fs.target" ];
  #   description = "Rollback root fs";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart =
  #       "${config.boot.zfs.package}/sbin/zfs rollback -r zpool/root@blank";
  #   };
  # };

  environment.etc."NetworkManager/system-connections" = {
    source = "${config.etcDir}/NetworkManager/system-connections/";
  };

  systemd.tmpfiles.rules = lib.mkIf (config.varDir != "/var") [
    "L /var/lib/bluetooth - - - - ${config.varDir}/lib/bluetooth"
  ];
  # End of Ephemeral OS
}