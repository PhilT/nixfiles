# Sync Unison with Suuno
# Runs on Minoo

{ config, lib, pkgs, ... }:

let
  mountsConfig = lib.lists.foldr (path: str: "mountpoint = ${path}\n${str}") "";
in
{
  imports = [ ./default.nix ];

  unison = {
    target = "suuno";
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
    extraConfig = ''
      perms = 0
      dontchmod = true

      ${mountsConfig config.unison.paths}
      forcepartial = Path pictures/showcase /data
      forcepartial = Path music /data
    '';
  };

  environment.systemPackages = with pkgs; [
    sshfs

    (writeShellScriptBin "sync_${config.unison.target}" ''
      ${pkgs.sshfs}/bin/sshfs ${config.unison.target}:/ /mnt/${config.unison.target} -p 8022 -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
      ${pkgs.unison}/bin/unison ${config.dataDir} /mnt/${config.unison.target} -include common $@
      /run/wrappers/bin/mount | grep ${config.unison.target} > /dev/null && /run/wrappers/bin/umount /mnt/${config.unison.target}
    '')
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/${config.unison.target} - ${config.username} users -"
  ];
}