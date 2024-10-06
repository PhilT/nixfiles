# Sync Unison between Phone and Spruce (Desktop) or Aramid (X1C)
{ name }: { config, pkgs, lib, ... }:

let
  extractIpAddress = "sed -En 's/.*${name} \((.*)\)/\1/p'";
in
{
  imports = [
    ./default.nix
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin name ''
      device_ip=nmap -sn 192.168.1.0/24 | ${extractIpAddress}
      unison ${name} /data ssh://$device_ip//data
    '')
  ];

  environment.etc."config/unison/${name}.prf" = {
    mode = "444";
    text = ''
      include common

      path = books
      path = documents
      path = music
      path = notes
      path = pictures/camera
      path = pictures/showcase
      path = sync
      path = txt

      forcepartial = pictures/showcase /data
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "d ${config.xdgConfigHome}/unison - phil users -"

    "L+ ${config.xdgConfigHome}/unison/${name}.prf - - - - /etc/config/unison/${name}.prf"
  ];
}