{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./minimal.nix
    ../../hardware/bluetooth.nix
    ../../plymouth.nix
    ../../common.nix
    ../../common_gui.nix
    ../../development.nix
    ../../studio.nix
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
    ../../desktop/light.nix

    # Windows
    ../../windows_backup.nix
  ];

  waybarModules = [
    "pulseaudio"
    "network"
    "cpu"
    "memory"
    "disk"
    "temperature"
    "bluetooth"
    "clock"
    "tray"
  ];

  # This appears to use quite a lot of resources
  # RGB software is also known to cause reprojection issues
  # and could be interferring with my Gaming setup
  # services.hardware.openrgb.enable = true;

  hardware.graphics.enable = true;

  # Support for Ploopy trackball (and supposedly GMMK 2 but isn't currently working)
  hardware.keyboard.qmk.enable = true;

  # Plymouth UI is a bit small without this
  boot.plymouth.extraConfig = "DeviceScale=2";
}