{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../minimal-configuration.nix
    ../../hardware/default.nix
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

  # Plymouth UI is a bit small without this
  boot.plymouth.extraConfig = "DeviceScale=2";
}