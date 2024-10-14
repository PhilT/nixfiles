{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    unison
    nmap
    sshfs
  ];

  environment.etc."config/unison/common.prf" = {
    mode = "444";
    text = ''
      # silent = true # Disable until testing is complete
      showarchive = true
      maxthreads = 30
      fastcheck = true # Speeds up checks on Windows systems (Unix already uses fastcheck)

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