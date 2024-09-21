{ config, lib, pkgs, ... }:
let
  colors = import ./macchiato.nix lib;
in with colors; {
  environment.etc."config/mako" = {
    mode = "444";
    text = ''
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