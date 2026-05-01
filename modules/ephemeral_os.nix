{ config, lib, pkgs, ... }:
let ZFS_ROLLBACK = "${config.boot.zfs.package}/sbin/zfs rollback -r";
in {
  # TODO: Move to more general location once the rest
  # of my machines are using it
  # We don't have a root@blank snapshot on Aramid yet so we can't do this
  # And /home isn't ready to be rolled back either
  #boot.initrd.systemd.services = {
  #  initrd-rollback-root = {
  #    after = [ "zfs-import-rpool.service" ];
  #    before = [ "sysroot.mount" "local-fs.target" ];
  #    description = "Rollback root filesystem";
  #    serviceConfig = {
  #      Type = "oneshot";
  #      ExecStart = "${ZFS_ROLLBACK} zpool/root@blank";
  #    };
  #  };
  #  initrd-rollback-home = {
  #    after = [ "zfs-import-rpool.service" ];
  #    before = [ "sysroot.mount" "local-fs.target" ];
  #    description = "Rollback home filesystem";
  #    serviceConfig = {
  #      Type = "oneshot";
  #      ExecStart = "${ZFS_ROLLBACK} zpool/home@blank";
  #    };
  #  };
  #};

  environment.etc."NetworkManager/system-connections" = {
    source = "${config.etcDir}/NetworkManager/system-connections/";
  };

  systemd.tmpfiles.rules = lib.mkMerge [
    [
      "L+ ${config.xdgConfigHome}/Slack - - - - ${config.persistedMachineDir}/Slack"
      "L+ ${config.xdgConfigHome}/vesktop - - - - ${config.persistedMachineDir}/vesktop"
    ]
    (lib.mkIf (config.varDir != "/var/lib") [
      "L /var/lib/bluetooth - - - - ${config.varDir}/lib/bluetooth"
    ])
  ];
}