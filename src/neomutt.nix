{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      neomutt
      urlscan       # View URLs in Emails (kind of important)
      links2        # For rendering HTML inline
      runningx      # Check if X is running so a browser can be started to view pages

    etc = {
      "mailcap".source = ../dotfiles/mailcap;
      "xdg/neomutt/neomuttrc".source = ../dotfiles/neomuttrc;
      "xdg/neomutt/secrets.muttrc".source = ../secrets/secrets.muttrc;
      "xdg/neomutt/aliases.muttrc".source = ../dotfiles/aliases.muttrc;
      "xdg/neomutt/dracula.muttrc".source = ../dotfiles/dracula.muttrc;
    };
  };
}
