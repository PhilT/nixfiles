# Sync Unison between Phone and Spruce (Desktop) or Aramid (X1C)
# FIXME: Some duplication exists between phone.nix and spruce.nix

{ name }: { config, pkgs, lib, ... }:

let
  paths = [
    "books"
    "documents"
    "music"
    "notes"
    "DCIM"
    "pictures/showcase"
    "sync"
    "txt"
  ];
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  mountsConfig = lib.lists.foldr (path: str: "mountpoint = ${path}\n${str}") "";
  root = "/data";
  folders = map (path: "d ${root}/${path} - phil users -") paths;
  extractIpAddress = "sed -En 's/.*${name} \\((.*)\\)/\\1/p'";
in
{
  imports = [
    ./default.nix
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin name ''
      device_ip=`nmap -sn 192.168.1.0/24 | ${extractIpAddress}`
      sshfs $device_ip:/ /mnt/${name} -p 8022 -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
      unison ${root} /mnt/${name} -include ${name} $@
      mount | grep ${name} > /dev/null && umount /mnt/${name}
    '')
  ];

  environment.etc."config/unison/${name}.prf" = {
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
    "d ${config.userHome} - phil users -"
    "d ${config.userHome}/.unison - phil users -"
    "d /mnt/${name} - phil users -"

    "L+ ${config.userHome}/.unison/${name}.prf - - - - /etc/config/unison/${name}.prf"
  ] ++ folders;
}