{ config, lib, pkgs, ... }:

{
  options.waybarModules = lib.mkOption {
    type = with lib.types; listOf str;
    default = [
      "pulseaudio"
      "cpu"
      "memory"
      "disk"
      "disk#games"
      "temperature"
      "bluetooth"
      "clock"
      "tray"
    ];
  };

  imports = [
    ./minimal.nix

    ../gaming.nix
    ../phil.nix
  ];

  config = {
    services.hardware.openrgb.enable = true;
    hardware.graphics.enable = true;

    environment.systemPackages = with pkgs; [
      ddcutil               # Control external monitor brightness

      (writeShellScriptBin "monlight" ''
        if [[ "$1" == "up" ]]; then
          amount=50
        elif [[ "$1" == "down" ]]; then
          amount=5
        else
          exit 1
        fi

        ddcutil setvcp 10 $amount --bus 1 &
        ddcutil setvcp 10 $amount --bus 2 &
      '')
    ];

    programs.kitty.fontSize = 9;
  };
}