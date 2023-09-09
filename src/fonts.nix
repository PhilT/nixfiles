{ config, pkgs, ... }:

{
  # fonts.fontDir.enable = true;
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      font-awesome
      source-sans
      (nerdfonts.override { fonts = [ "DroidSansMono" ]; })
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "DroidSansMono Nerd Font Complete Mono" ];
	      serif = [ "Noto Serif" ];
	      sansSerif = [ "Noto Sans" ];
      };
    };
  };
}
