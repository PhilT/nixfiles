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
    ../adjustlight.nix
    ../phil.nix
  ];

  config = {
    hardware.sensor.iio.enable = true;

    # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)
    services.auto-cpufreq.enable = true;

    services.syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
    services.syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";

    environment.systemPackages = with pkgs; [
      (callPackage ../iio-hyprland.nix {})
      flashrom
      pamixer
      playerctl
    ];

    programs.kitty.fontSize = 9;
    programs.light.enable = true;
  };
}