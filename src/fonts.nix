{ config, pkgs, ... }:

{
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    source-sans
  ];

  system.userActivationScripts.fonts = ''
    [ -e $HOME/.local/share/fonts ] || ln -s /run/current-system/sw/share/X11/fonts $HOME/.local/share/fonts
  '';
}
