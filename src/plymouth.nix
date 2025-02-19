# Graphical login for drive encryption
# Logs to /var/log/boot.log

{ config, lib, pkgs, ... }: {
  boot.plymouth = {
    enable = true;
    font = "${pkgs.atkinson-hyperlegible}/share/fonts/opentype/AtkinsonHyperlegible-Regular.otf";
  };
  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "macchiato";
}