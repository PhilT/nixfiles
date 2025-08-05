{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./minimal.nix
    ../../hardware/bluetooth.nix
    ../../ephemeral_os.nix
    ../../plymouth.nix
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

    # Desktop
    ../../desktop/light.nix
  ];

  waybarModules = [
    "pulseaudio"
    "cpu"
    "memory"
    "disk"
    "temperature"
    "clock"
    "tray"
  ];

  hardware.graphics.enable = true;

  keyboardLayout = "us";
}