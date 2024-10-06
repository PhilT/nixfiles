{ config, pkgs, lib, ... }:

{
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  environment.systemPackages = with pkgs; [
    unison
    nmap
  ];

  environment.etc."config/unison/common.prf" = {
    mode = "444";
    text = ''
      silent = true
      ignore = Name .thumbnails
      ignore = Name .devenv
      ignore = Name *.tmp
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "d ${config.xdgConfigHome}/unison - phil users -"

    "L+ ${config.xdgConfigHome}/unison/common.prf - - - - /etc/unison/common.prf"
  ];

  # Remove all .stfolder/.stfolder (1) and .stignore files from /data/**
  # once migrated to unison
}