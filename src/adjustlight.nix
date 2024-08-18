{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [

    (writeShellScriptBin "adjustlight" ''
      level=$(brightnessctl | sed -nE 's/.*Current brightness: ([0-9]+) .*/\1/p')

      if [ "$1" = "up" ]; then
        brightnessctl set +1
      else

        [ $level -ge "4" ] && brightnessctl set 1-
      fi
    '')
  ];
}