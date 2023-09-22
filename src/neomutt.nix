{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      neomutt
      urlscan       # View URLs in Emails (kind of important)
      links2        # For rendering HTML inline
      runningx      # Check if X is running so a browser can be started to view pages

      himalaya
    ];

    etc = {
      "himalaya.toml".source = ../dotfiles/himalaya.toml;
      "mailcap".source = ../dotfiles/mailcap;
      "xdg/neomutt/neomuttrc".source = ../dotfiles/neomuttrc;
      "xdg/neomutt/secrets.muttrc".source = ../secrets/secrets.muttrc;
      "xdg/neomutt/dracula.muttrc".source = ../dotfiles/dracula.muttrc;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/himalaya - phil users"
    "L+ ${config.xorg.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya.toml"
  ];
}
