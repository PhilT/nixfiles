{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "mail" "neomutt")

      neomutt
    ];

    etc = {
      "mailcap".source = ../dotfiles/mailcap;
      "xdg/neomutt/neomuttrc".source = ../dotfiles/neomuttrc;
      "xdg/neomutt/secrets.muttrc".source = ../secrets/secrets.muttrc;
      "xdg/neomutt/dracula.muttrc".source = ../dotfiles/dracula.muttrc;
    };
  };
}
