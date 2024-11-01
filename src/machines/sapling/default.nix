{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../minimal-configuration.nix
    ../../hardware/default.nix
    ../../hardware/bluetooth.nix
    ../../common.nix
    ../../development.nix

    # Sync
    # ?

    # Windowing
    ../../sway/mako.nix
    ../../sway/tofi.nix
    ../../sway/waybar.nix
    ../../sway/default.nix

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];
}