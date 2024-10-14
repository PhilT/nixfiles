{ config, lib, pkgs, ... }:
{
  options.waybarModules = lib.mkOption {
    type = with lib.types; listOf str;
    default = [
      "pulseaudio"
      "network"
      "cpu"
      "memory"
      "disk"
      "temperature"
      "backlight"
      "battery"
      "clock"
      "tray"
    ];
  };

  imports = [
    ./minimal.nix
    ../../common.nix

    # User
    ../../users/phil.nix

    # Sync
    ../../ssh.nix
    ../../unison/spruce.nix
    ../../unison/suuno.nix

    # Windowing
    ../../sway/mako.nix
    ../../sway/tofi.nix
    ../../sway/waybar.nix
    ../../sway/default.nix

    # Laptops
    ../../laptop.nix
    ../../light.nix
  ];

  config = {
    hardware.sensor.iio.enable = true; # Screen rotation daemon

    environment.systemPackages = with pkgs; [
      flashrom
      wvkbd # Onscreen keyboard
    ];
  };
}