{ config, lib, pkgs, ... }:
{
  imports = [
    <catppuccin/modules/nixos>

    ./minimal.nix
    ../../common.nix
    ../../development.nix

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
    "clock"
    "tray"
  ];

  # Graphical login for drive encryption
  boot.plymouth = {
    enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "macchiato";
  };

  hardware.sensor.iio.enable = true; # Screen rotation daemon

  environment.systemPackages = with pkgs; [
    flashrom
    wvkbd # Onscreen keyboard
  ];
}