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
  services.hardware.openrgb.enable = true;
  hardware.graphics.enable = true;
}