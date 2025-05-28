{ config, lib, pkgs, ... }: {

  environment.etc."machine/README" = {
    mode = "444";
    text = ''
      This folder contains machine specific data that shouldn't be wiped on boot but
      doesn't need syncing between machines because it is sensitive (e.g. SSH keys)
      or can be regenerated but effort is required to do so.
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.dataDir} - ${config.username} users -"
    "d ${config.dataDir}/machines - ${config.username} users -"

    "L+ ${config.dataDir}/machines - - - - /etc/machine/README"
  ];
}