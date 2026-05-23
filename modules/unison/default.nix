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
    xferbycopying = true
    times = true

    copyonconflict = true
    prefer = newer
    retry = 5

    backupcurr = Path books
    backupcurr = Path calibre_library
    backupcurr = Path documents
    backupcurr = Path home
    backupcurr = Path imported_notes
    backupcurr = Path sync
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

    # Cache and build artifacts
    ignore = Name .cache
    ignore = Name node_modules
    ignore = Name target
    ignore = Name dist
    ignore = Name build
    ignore = Name .gradle

    # Version control
    ignore = Name .git

    # OS files
    ignore = Name .DS_Store
    ignore = Name Thumbs.db
    ignore = Name desktop.ini

    # Editor files
    ignore = Name .vscode
    ignore = Name .idea
    ignore = Name *.swp
    ignore = Name *.swo

    ignorenot = Name CLAUDE.md
    ignorenot = Name UNISON_NOTES.md

    ignore = Path .Trash*
    ignore = Path backups
    ignore = Regex ^code/[^/][^/]*$
    ignore = Path downloads
    ignore = Path etc
    ignore = Path games
    ignore = Path machine
    ignore = Path notes
    ignore = Path var
    ignore = Path vdisks
    ignore = Regex ^work/[^/][^/]*$

    # Synced when starting and stopping Chromium with a manual rsync run. To
    # ensure integrity we need to do a one way sync. See app-sync in chromium.nix.
    ignore = Path home/chromium

    # Containers (at least milvus-vector-db) are synced manually with
    # rsync -a --progress /data/containers phil@minoo:/data/
    ignore = Path containers

    # Claude Code state data to exclude
    ignore = Path home/claude/local
    ignore = Path home/claude/projects
    ignore = Path home/claude/statsig
    ignore = Path home/claude/todos
    ignore = Path home/claude/debug
    ignore = Path home/claude/file-history
    ignore = Path home/claude/plugins
    ignore = Path home/claude/telemetry
    ignore = Path home/claude/sessions
    ignore = Path home/claude/session-env
    ignore = Path home/claude/shell-snapshots
    ignore = Path home/claude/paste-cache
    ignore = Path home/claude/cache
    ignore = Path home/claude/backups
    ignore = Path home/claude/ide
    ignore = Path home/claude/history.jsonl
    ignore = Path home/claude/stats-cache.json
    ignore = Path home/claude/mcp-needs-auth-cache.json

    # 3rd party code is not committed so we sync it to local changes such as shell.nix
    ignorenot = Path code/3rd-party

    # These folders/files are not versioned so we sync them
    ignorenot = Path code/archive
    ignorenot = Path work/work.nix
    ignorenot = Path work/sync
    ignorenot = Path work/zuno
    ignore = Path work/zuno/mono

    ${config.unison.extraConfig}
  '';

  # The pathsConfig is only needed for Suuno now
  # as we sync everything to Minoo with the above
  # filters.
  environment.etc."unison/paths.prf".text = ''
    repeat = watch
    watch = true

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