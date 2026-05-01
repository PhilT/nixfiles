{ config, pkgs, ... }: {
  fonts = {
    packages = with pkgs; [
      corefonts
      atkinson-hyperlegible-next
      atkinson-hyperlegible-mono
      noto-fonts
      noto-fonts-color-emoji
      source-sans
      roboto-mono
      nerd-fonts.ubuntu
      nerd-fonts.ubuntu-mono
      nerd-fonts.jetbrains-mono
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
	      monospace = [ "Atkinson Hyperlegible Mono" ];
	      serif = [ "Atkinson Hyperlegible Next" ];
	      sansSerif = [ "Atkinson Hyperlegible Next" ];
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