{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brightnessctl     # Control display brightness with laptop keys

    (writeShellScriptBin "light" ''
      level=$(brightnessctl | sed -nE 's/.*Current brightness: ([0-9]+) .*/\1/p')

      if [ "$1" = "bright" ]; then
        brightnessctl --restore
      elif [ "$1" = "dim" ]; then
        brightnessctl --save
        brightnessctl set 10%
      elif [ "$1" = "up" ]; then
        brightnessctl set +5%
      elif [ "$1" = "down" ]; then
        brightnessctl set 5%-
      elif [[ "$1" == "off" ]]; then
        swaymsg "output eDP-1 power off"
      elif [[ "$1" == "on" ]]; then
        swaymsg "output eDP-1 power on"
      else
        exit 1
      fi
    '')
  ];
}