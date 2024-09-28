{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      atkinson-hyperlegible
      noto-fonts
      noto-fonts-emoji
      source-sans
      roboto-mono
      (nerdfonts.override { fonts = [ "Ubuntu" "UbuntuMono" "JetBrainsMono" ]; })
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "JetBrainsMono Nerd Font" ];
	      serif = [ "Atkinson Hyperlegible" ];
	      sansSerif = [ "Atkinson Hyperlegible" ];
      };
    };
  };
}