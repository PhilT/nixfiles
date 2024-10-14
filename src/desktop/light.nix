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
      else
        exit 1
      fi

      ddcutil setvcp 10 $amount --bus 1 &
      ddcutil setvcp 10 $amount --bus 2 &
    '')
  ];
}