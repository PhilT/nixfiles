{ config, lib, pkgs, ... }:
let
  colors = import ../macchiato.nix lib;
in with colors; {
  programs.sway.extraPackages = with pkgs; [
    mako
  ];

  environment.etc."config/mako" = {
    mode = "444";
    text = ''
      font=monospace 18
      width=500
      height=300
      default-timeout=5000
      background-color=${hex base}
      text-color=${hex text}
      border-color=${hex blue}
      border-radius=2

      [urgency=normal]
      border-color=${hex mauve}

      [urgency=critical]
      border-color=${hex red}
    '';
  };
}