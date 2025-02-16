{ config, pkgs, lib, ... }:
let
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  folders = map (path: "d ${config.dataDir}/${path} - ${config.username} users -");
  unisonDir = "${config.persistedHomeDir}/unison";
in
{
  imports = [ ./options.nix ];
  environment.systemPackages = with pkgs; [ unison ];
  environment.variables.UNISON = unisonDir;

  environment.etc."unison/common.prf".text = ''
    sshcmd = /run/current-system/sw/bin/ssh
    batch = true
    dumbtty = true
    maxthreads = 20
    fastcheck = true
    times = true
    watch = true

    copyonconflict = true
    prefer = newer
    repeat = watch
    retry = 5

    ignore = Name .thumbnails
    ignore = Name .devbox
    ignore = Name .direnv
    ignore = Name *.tmp
    ignore = Name .*~
    ignore = Name *~

    ignore = Path work/*
    ignorenot = Path work/work.nix
    ignorenot = Path work/sync

    ${pathsConfig config.unison.paths}
    ${config.unison.extraConfig}
  '';

  systemd.services.unison = {
    enable = true;
    description = "Unison filesync";
    serviceConfig = {
      Type = "simple";
      ExecStart = "/run/current-system/sw/bin/sync_${config.unison.target}";
      ExecStop = "/run/current-system/sw/bin/pkill unison";
      Restart = "always";
      RestartSec = "5";
      RestartSteps = "10";
      RestartMaxDelaySec = "1800";
      User = config.username;
      Group = "users";
    };
    after = config.unison.waitFor;
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };

  systemd.tmpfiles.rules = [
    "d ${unisonDir} - ${config.username} users -"
    "L+ ${unisonDir}/common.prf - - - - /etc/unison/common.prf"
  ] ++ (folders config.unison.paths);
}