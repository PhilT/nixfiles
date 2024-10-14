# Sync Unison between Aramid (X1C) and Spruce (Desktop)
# FIXME: Some duplication exists between phone.nix and spruce.nix

{ config, pkgs, lib, ... }:

let
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
  extractIpAddress = "sed -En 's/.*spruce \\((.*)\\)/\\1/p'";
in
{
  imports = [
    ./default.nix
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "spruce" ''
      spruce_ip=`nmap -sn 192.168.1.0/24 | ${extractIpAddress}`
      unison ${root} ssh://$spruce_ip//${root} -include spruce $@
    '')
  ];

  environment.etc."config/unison/spruce.prf" = {
    mode = "444";
    text = ''
      include common

      ${pathsConfig paths}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"

    "L+ ${config.userHome}/.unison/spruce.prf - - - - /etc/config/unison/spruce.prf"
  ] ++ folders;
}