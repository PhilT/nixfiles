{ config, pkgs, lib, ... }:
let
  pathsConfig = lib.lists.foldr (path: str: "path = ${path}\n${str}") "";
  folders = map (path: "d ${config.dataDir}/${path} - ${config.username} users -");
  unisonDir = "${config.persistedMachineDir}/unison";
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

    copyonconflict = true
    prefer = newer
    retry = 5

    backupcurr = Path books
    backupcurr = Path calibre_library
    backupcurr = Path documents
    backupcurr = Path home
    backupcurr = Path notes
    backupcurr = Path sync
    backupcurr = Path txt
    backuplocation = central
    maxbackups = 2
    backupdir = ${config.dataDir}/backups

    ignore = Name .thumbnails
    ignore = Name .devbox
    ignore = Name .direnv
    ignore = Name logs
    ignore = Name *.tmp
    ignore = Name *.lock
    ignore = Name .*~
    ignore = Name *~
    ignorenot = Name CLAUDE.md

    # This needs to be moved to machine/
    ignore = Path milvus-vector-db

    ignore = Path .Trash*
    ignore = Path backups
    ignore = Path code/*
    ignore = Path work/*
    ignore = Path downloads
    ignore = Path etc
    ignore = Path machine
    ignore = Path var
    ignore = Path vdisks
    ignore = Path home/firefox/lock
    ignore = Path home/thunderbird/lock

    # Claude Code state data to exclude
    ignore = Path home/claude/local
    ignore = Path home/claude/projects
    ignore = Path home/claude/statsig
    ignore = Path home/claude/todos

    # 3rd party code is not committed so we sync it to grab files such as shell.nix
    ignorenot = Path code/3rd-party

    ignorenot = Path code/archive
    ignorenot = Path work/work.nix
    ignorenot = Path work/sync

    ${config.unison.extraConfig}
  '';

  # The pathsConfig is only needed for Suuno now
  # as we sync everything to Minoo with the above
  # filters.
  environment.etc."unison/paths.prf".text = ''
    repeat = watch
    watch = true

    # These are synced when starting and stopping FF and TB with a manual unison
    # run. See app-sync in firefox.nix.
    ignore = Path home/firefox
    ignore = Path home/thunderbird

    ${pathsConfig config.unison.paths}
  '';

  systemd.services.unison = {
    enable = true;
    description = "Unison filesync";
    startLimitIntervalSec = 0;
    serviceConfig = {
      Type = "simple";
      ExecStart = "/run/current-system/sw/bin/sync_${config.unison.target} -include paths";
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
    "L+ ${unisonDir}/paths.prf - - - - /etc/unison/paths.prf"

    "d ${config.dataDir}/backups - ${config.username} users -" # Unison backup folder
  ] ++ (folders config.unison.paths);
}