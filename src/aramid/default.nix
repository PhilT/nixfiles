# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

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
      "bluetooth"
      "clock"
      "tray"
    ];
  };

  imports = [
    ./minimal.nix

    ../unison/spruce.nix
    ../unison/suuno.nix
    ../adjustlight.nix
    ../phil.nix
  ];

  config = {
    services.fprintd.enable = true;
    hardware.sensor.iio.enable = true;

    # CPU power/speed optimiser https://github.com/AdnanHodzic/auto-cpufreq
    services.auto-cpufreq.enable = true;

    programs.kitty.fontSize = 9;
    programs.light.enable = true;

    environment.systemPackages = with pkgs; [
      brightnessctl
      pamixer
      playerctl
    ];
  };
}