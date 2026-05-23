{ config, pkgs, ... }: {
  systemd.tmpfiles.rules = [
    "d /data/mail - ${config.username} users -"
    "d /data/mail/namecheap - ${config.username} users -"
    "L+ ${config.homeDir}/.mbsyncrc - - - - /etc/mbsyncrc"
    "d ${config.xdgConfigHome}/himalaya - ${config.username} users -"
    "L+ ${config.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya/config.toml"
  ];

  environment = {
    sessionVariables = {
      NOTMUCH_CONFIG = "/etc/notmuch-config";
    };

    etc = {
      "mbsyncrc".source = ../dotfiles/mbsyncrc;
      "notmuch-config".source = ../dotfiles/notmuch-config;
      "himalaya/config.toml".source = ../dotfiles/himalaya-config.toml;
    };
  };
}
