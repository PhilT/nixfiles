{ config, pkgs, ... }:

{
  # fonts.fontDir.enable = true;
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      source-sans
      (nerdfonts.override { fonts = [ "Ubuntu" "UbuntuMono" "JetBrainsMono" ]; })
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "JetBrainsMono Nerd Font" ];
	      serif = [ "Noto Serif" ];
	      sansSerif = [ "Noto Sans" ];
      };
    };
  };
}