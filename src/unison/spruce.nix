# Sync Unison between Aramid (X1C) and Spruce (Desktop)

{ config, pkgs, lib, ... }:

let
  extractIpAddress = "sed -En 's/.*spruce \((.*)\)/\1/p'";
in
{
  imports = [
    ./default.nix
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "spruce" ''
      spruce_ip=nmap -sn 192.168.1.0/24 | ${extractIpAddress}
      unison /data ssh://$spruce_ip//data -include default
    '')
  ];

  environment.etc."config/unison/spruce.prf" = {
    mode = "444";
    text = ''
      include common

      path = books
      path = code
      path = documents
      path = music
      path = music_extra
      path = notes
      path = other
      path = pictures
      path = screenshots
      path = studio
      path = sync
      path = thunderbird_profile
      path = txt
      path = videos
      path = work
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "d ${config.xdgConfigHome}/unison - phil users -"

    "L+ ${config.xdgConfigHome}/unison/spruce.prf - - - - /etc/unison/spruce.prf"
  ];
}