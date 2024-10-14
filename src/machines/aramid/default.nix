# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
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
    ../../laptop/default.nix
    ../../laptop/light.nix
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

  boot.plymouth = {
    catppuccin.enable = true;
    catppuccin.flavor = "macchiato";
  };

  services.fprintd.enable = true;
}