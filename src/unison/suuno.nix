# Sync Unison with Suuno
# Runs on Minoo
# FIXME: Some duplication exists between minoo.nix and suuno.nix

{ config, lib, pkgs, ... }:

let
  paths = [
    "books"
    "documents"
    "music"
    "notes"
    "pictures/showcase"
    "pictures/camera"
    "sync"
    "txt"
  ];
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  mountsConfig = lib.lists.foldr (path: str: "mountpoint = ${path}\n${str}") "";
  root = "/data";
  folders = map (path: "d ${root}/${path} - ${config.username} users -") paths;
in
{
  imports = [
    ./default.nix
  ];

  unisonTarget = "suuno";
  unisonTargetIpAddress = config.ipAddresses."${config.unisonTarget}";

  environment.systemPackages = with pkgs; [
    sshfs

    (writeShellScriptBin "sync_${config.unisonTarget}" ''
      sshfs ${config.unisonTargetIpAddress}:/ /mnt/${config.unisonTarget} -p 8022 -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
      unison ${root} /mnt/${config.unisonTarget} -include ${config.unisonTarget} $@
      mount | grep ${config.unisonTarget} > /dev/null && umount /mnt/${config.unisonTarget}
    '')
  ];

  environment.etc."config/unison/${config.unisonTarget}.prf" = {
    mode = "444";
    text = ''
      include common

      perms = 0
      dontchmod = true

      ${pathsConfig paths}
      ${mountsConfig paths}
      forcepartial = Path pictures/showcase /data
      forcepartial = Path music /data
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.userHome} - ${config.username} users -"
    "d ${config.userHome}/.unison - ${config.username} users -"
    "d /mnt/${config.unisonTarget} - ${config.username} users -"

    "L+ ${config.userHome}/.unison/${config.unisonTarget}.prf - - - - /etc/config/unison/${config.unisonTarget}.prf"
  ] ++ folders;
}