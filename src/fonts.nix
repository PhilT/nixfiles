{ config, pkgs, ... }:

{
  # fonts.fontDir.enable = true;
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      source-sans
      (nerdfonts.override { fonts = [ "Ubuntu" "UbuntuMono" ]; })
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "UbuntuMono Nerd Font Mono" ];
	      serif = [ "Noto Serif" ];
	      sansSerif = [ "Noto Sans" ];
      };
    };
  };
}
