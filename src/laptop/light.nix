{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl     # Control display brightness with laptop keys

    (writeShellScriptBin "light" ''
      level=$(brightnessctl | sed -nE 's/.*Current brightness: ([0-9]+) .*/\1/p')

      if [ "$1" = "bright" ]; then
        brightnessctl set +1 # Tweak once tested on Aramid
      elif [ "$1" = "dim" ]; then
        brightnessctl set 1- # Tweak once tested on Aramid
      elif [ "$1" = "up" ]; then
        brightnessctl set +1
      elif [ "$1" = "down" ]; then
        brightnessctl set 1-
      else
        exit 1
      fi
    '')
  ];
}