{ config, pkgs, ... }:
let
  unisonDir = "${config.persistedMachineDir}/unison";
in
{
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
}
