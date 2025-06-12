{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      corefonts
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

  console = {
    packages= with pkgs;[ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    useXkbConfig = true;
  };

  services.kmscon = {
    enable = true;
    hwRender = true;
    extraConfig = ''
      font-name=monospace
      font-size=20
    '';
  };

}