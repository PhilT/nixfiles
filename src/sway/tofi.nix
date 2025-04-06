{ config, pkgs, ... }:
{
  programs.sway.extraPackages = with pkgs; [
    tofi
  ];

  environment = {
    etc = {
      "config/tofi.ini" = {
        mode = "444";
        text = ''
          font = ${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMonoNerdFontMono-Regular.ttf
          font-size = 18

          text-color = #cad3f5
          prompt-color = #ed8796
          selection-color = #eed49f
          background-color = #181926cc

          outline-width = 0
          border-width = 2
          border-color = #c6a0f6
          corner-radius = 5

          width = 1000
          height = 500
        '';
      };
    };
  };
}