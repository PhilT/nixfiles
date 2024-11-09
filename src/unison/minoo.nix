# Sync Unison with Minoo
# Runs on Spruce and Aramid
# TODO: Some duplication exists between minoo.nix and suuno.nix

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
in
{
  imports = [
    ./default.nix
  ];

  unisonTarget = "minoo";
  unisonTargetIpAddress = config.ipAddresses.minoo;

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sync_${config.unisonTarget}" ''
      unison ${root} ssh://${config.unisonTargetIpAddress}//${root} -include ${config.unisonTarget} $@
    '')
  ];

  environment.etc."config/unison/${config.unisonTarget}.prf" = {
    mode = "444";
    text = ''
      include common

      ${pathsConfig paths}
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"

    "L+ ${config.userHome}/.unison/${config.unisonTarget}.prf - - - - /etc/config/unison/${config.unisonTarget}.prf"
  ] ++ folders;
}