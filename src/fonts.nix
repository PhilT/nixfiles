{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      atkinson-hyperlegible
      noto-fonts
      noto-fonts-emoji
      source-sans
      roboto-mono
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.jetbrains-mono
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