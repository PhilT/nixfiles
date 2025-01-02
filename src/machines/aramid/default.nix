# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../hardware/default.nix
    ../../hardware/bluetooth.nix
    ../../minimal-configuration.nix
    ../../common.nix
    ../../common_gui.nix
    ../../development.nix

    # Sync
    ../../ssh.nix
    ../../unison/minoo.nix

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

  # Graphical login for drive encryption
  boot.plymouth.enable = true;
  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "macchiato";

  hardware.graphics.enable = true;
}