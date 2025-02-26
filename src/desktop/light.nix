{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    ddcutil               # Control external monitor brightness

    (writeShellScriptBin "light" ''
      if [[ "$1" == "bright" ]]; then
        amount=50
      elif [[ "$1" == "dim" ]]; then
        amount=5
      elif [[ "$1" == "up" ]]; then
        amount="+ 5"
      elif [[ "$1" == "down" ]]; then
        amount="- 5"
      elif [[ "$1" == "off" ]]; then
        swaymsg "output DP-1 power off"
        swaymsg "output HDMI-A-1 power off"
      elif [[ "$1" == "on" ]]; then
        swaymsg "output DP-1 power on"
        swaymsg "output HDMI-A-1 power on"
      else
        exit 1
      fi

      # Use sudo ddcutil detect to get bus number
      sudo ddcutil setvcp 10 $amount --bus 3 &
      sudo ddcutil setvcp 10 $amount --bus 9 &
    '')
  ];
}