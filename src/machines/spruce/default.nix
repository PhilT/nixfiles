{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../minimal-configuration.nix
    ../../common.nix
    ../../common_gui.nix
    ../../development.nix
    ../../qemu.nix

    # Sync
    ../../ssh.nix
    ../../unison/minoo.nix

    # Windowing
    ../../sway/mako.nix
    ../../sway/tofi.nix
    ../../sway/waybar.nix
    ../../sway/default.nix

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
    ../../desktop/gaming.nix
  ];

  waybarModules = [
    "pulseaudio"
    "cpu"
    "memory"
    "disk"
    "disk#games"
    "temperature"
    "bluetooth"
    "clock"
    "tray"
  ];

  # Graphical login for drive encryption
  boot.plymouth.enable = true;
  catppuccin.plymouth.enable = true;
  catppuccin.plymouth.flavor = "macchiato";

  services.hardware.openrgb.enable = true;
  hardware.graphics.enable = true;

  # Support for Ploopy trackball (and supposedly GMMK 2 but isn't currently working)
  hardware.keyboard.qmk.enable = true;

  environment.systemPackages = with pkgs; [
    virglrenderer
  ];
}