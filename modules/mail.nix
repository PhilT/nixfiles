{ config, lib, pkgs, ... }:
let
  unisonDir = "${config.persistedMachineDir}/unison";
in
{
  imports = [
    ./scripts/mail-sync.nix
    ./scripts/mail-lock.nix
    ./scripts/mail-archive.nix
  ];

  systemd.tmpfiles.rules = [
    "d /data/mail - ${config.username} users -"
    "d /data/mail/namecheap - ${config.username} users -"
    "L+ ${config.homeDir}/.mbsyncrc - - - - /etc/mbsyncrc"
    "d ${config.xdgConfigHome}/himalaya - ${config.username} users -"
    "L+ ${config.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya/config.toml"
    "d ${config.xdgConfigHome}/notmuch - ${config.username} users -"
    "d ${config.xdgConfigHome}/notmuch/default - ${config.username} users -"
    "L+ ${config.xdgConfigHome}/notmuch/default/config - - - - /etc/notmuch/config"
    "L+ ${unisonDir}/mail.prf - - - - /etc/unison/mail.prf"
  ];

  environment = {
    etc = {
      "mbsyncrc".source = ../dotfiles/mbsyncrc;
      "notmuch/config".source = ../dotfiles/notmuch-config;
      "himalaya/config.toml".source = ../dotfiles/himalaya-config.toml;

      # Cold-archive backup profile for `sync_minoo_mail`. Live mbsync-managed
      # folders are deliberately NOT included — letting their per-client
      # filenames (with `,U=N` UID hints) cross machines via the server caused
      # mbsync state drift ("UID N beyond highest assigned"). IMAP is the only
      # transport for live mail.
      #
      # Only the Archive years excluded from mbsync's Patterns are synced
      # here. Add new years to this list (and to mbsyncrc Patterns) when the
      # cutoff moves.
      "unison/mail.prf".text = ''
        root = /data/mail
        root = ssh://minoo//data/mail

        sshcmd = /run/current-system/sw/bin/ssh
        batch = true
        dumbtty = true
        fastcheck = true
        times = true
        prefer = newer
        copyonconflict = true
        retry = 5

        path = namecheap/Archive/2014
        path = namecheap/Archive/2015
        path = namecheap/Archive/2016
        path = namecheap/Archive/2017
        path = namecheap/Archive/2018
        path = namecheap/Archive/2019
        path = namecheap/Archive/2020

        ignore = Name .notmuch
        ignore = Name *.tmp
        ignore = Name *.lock
        ignore = Name .mbsyncstate
        ignore = Name .uidvalidity
      '';
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "sync_minoo_mail" ''
        UNISON=${unisonDir} ${pkgs.unison}/bin/unison mail "$@"
      '')
    ];
  };

  # Periodic mbsync. User unit so it runs in the user's environment
  # (XDG_RUNTIME_DIR, notmuch DB perms). The local flock inside mail-sync
  # keeps overlapping timer ticks and manual invocations safe.
  systemd.user.services.mail-sync = {
    description = "Mail sync cycle (mbsync + notmuch)";
    # mbsync's PassCmd shells out to `nixx`; user units don't inherit the
    # shell's PATH.
    environment.PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/mail-sync";
    };
  };

  systemd.user.timers.mail-sync = {
    description = "Periodic mail sync";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "2min";
      AccuracySec = "30s";
      RandomizedDelaySec = "30s";
    };
  };
}
