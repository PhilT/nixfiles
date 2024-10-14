# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
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

  waybarModules = [
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

  services.fprintd.enable = true;
}