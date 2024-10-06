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

    ../unison/spruce.nix
    ../adjustlight.nix
    ../phil.nix
  ];

  config = {
    hardware.sensor.iio.enable = true;

    # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)
    services.auto-cpufreq.enable = true;

    environment.systemPackages = with pkgs; [
      brightnessctl
      flashrom
      pamixer
      playerctl
      wvkbd # Onscreen keyboard
    ];

    programs.kitty.fontSize = 9;
    programs.light.enable = true;
  };
}