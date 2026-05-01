{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./minimal.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/ephemeral_os.nix
    ../../modules/plymouth.nix
    ../../modules/common.nix
    ../../modules/common_gui.nix
    ../../modules/development.nix

    # Sync
    ../../modules/ssh.nix
    ../../modules/unison/minoo.nix

    # Windowing
    ../../modules/sway/mako.nix
    ../../modules/sway/tofi.nix
    ../../modules/sway/waybar.nix
    ../../modules/sway/default.nix

    # Desktop
    ../../modules/desktop/light.nix
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