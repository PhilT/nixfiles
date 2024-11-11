{ config, pkgs, lib, ... }: {
  # DHCP Reservations setup on Linksys Router
  ipAddresses = {
    aramid = "192.168.1.87";
    minoo = "192.168.1.248";
    spruce = "192.168.1.226";
    suuno = "192.168.1.205";
  };

  environment.systemPackages = with pkgs; [
    unison
  ];

  environment.etc."config/unison/common.prf" = {
    mode = "444";
    text = ''
      # silent = true # Disable until testing is complete
      auto = true
      showarchive = true
      maxthreads = 30
      fastcheck = true # Speeds up checks on Windows systems (Unix already uses fastcheck)
      copyonconflict = true

      ignore = Name .thumbnails
      ignore = Name .devenv
      ignore = Name *.tmp
      ignore = Name .*~
      ignore = Name *~
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"

    "L+ ${config.userHome}/.unison/common.prf - - - - /etc/config/unison/common.prf"
  ];

  # Remove all .stfolder/.stfolder (1) and .stignore files from /data/**
  # once migrated to unison
}