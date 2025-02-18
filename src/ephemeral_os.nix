{ config, lib, pkgs, ... }: {
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

  fileSystems = {
    # TODO: Enable once we're happy to have it removed on boot
    # "/home" = {
    #   device = "zpool/home";
    #   fsType = "zfs";
    # };
  };

  environment.etc."NetworkManager/system-connections" = {
    source = "${config.etcDir}/NetworkManager/system-connections/";
  };

  systemd.tmpfiles.rules = lib.mkMerge [
    [
      "L+ ${config.xdgConfigHome}/Slack - - - - ${config.persistedHomeDir}/Slack"
      "L+ ${config.xdgConfigHome}/vesktop - - - - ${config.persistedHomeDir}/vesktop"
    ]
    (lib.mkIf (config.varDir != "/var/lib") [
      "L /var/lib/bluetooth - - - - ${config.varDir}/lib/bluetooth"
    ])
  ];
}