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

      # Dedicated profile for syncing /data/mail to minoo. Invoked on demand
      # by the mail-sync cycle (lock -> unison -> mbsync -> notmuch -> unison).
      # The notmuch index is per-machine, so .notmuch is excluded.
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

        ignore = Name .notmuch
        ignore = Name *.tmp
        ignore = Name *.lock
      '';
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "sync_minoo_mail" ''
        UNISON=${unisonDir} ${pkgs.unison}/bin/unison mail "$@"
      '')
    ];
  };

  # Periodic sync + trailing push on session/shutdown.
  # Per-user units so the cycle runs in the user's environment (XDG_RUNTIME_DIR,
  # ssh agent socket, notmuch DB perms). The local flock inside mail-sync makes
  # overlap between the timer, the shutdown unit, and manual invocation safe.
  # TODO: gate the timer on user-idle so an unattended-but-on machine releases
  # the field to the other host.
  systemd.user.services.mail-sync = {
    description = "Mail sync cycle (unison <-> mbsync <-> notmuch)";
    # mbsync's PassCmd shells out to `nixx`; ssh / notmuch / unison need the
    # standard NixOS PATH too. User units don't inherit the shell's PATH.
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

  systemd.user.services.mail-sync-shutdown = {
    description = "Trailing mail sync on session shutdown";
    wantedBy = [ "default.target" ];
    environment.PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      ExecStop = "/run/current-system/sw/bin/mail-sync";
      TimeoutStopSec = "180";
    };
  };
}
