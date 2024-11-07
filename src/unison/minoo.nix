# Sync Unison with Minoo
# Runs on Spruce and Aramid
# FIXME: Some duplication exists between minoo.nix and suuno.nix

{ config, pkgs, lib, ... }:

let
  name = "minoo";
  paths = [
    "books"
    "documents"
    "music"
    "music_extra"
    "notes"
    "other"
    "pictures"
    "screenshots"
    "studio"
    "sync"
    "thunderbird_profile"
    "txt"
    "videos"
  ];
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  root = config.dataDir;
  folders = map (path: "d ${root}/${path} - ${config.username} users -") paths;
  extractIpAddress = "sed -En 's/.*${name} \\((.*)\\)/\\1/p'";
in
{
  imports = [
    ./default.nix
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sync_${name}" ''
      device_ip=`nmap -sn 192.168.1.0/24 | ${extractIpAddress}`
      unison ${root} ssh://$device_ip//${root} -include ${name} $@
    '')
  ];

  environment.etc."config/unison/${name}.prf" = {
    mode = "444";
    text = ''
      include common

      ${pathsConfig paths}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"

    "L+ ${config.userHome}/.unison/${name}.prf - - - - /etc/config/unison/${name}.prf"
  ] ++ folders;
}