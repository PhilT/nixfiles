# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

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

    # Sync
    ../../ssh.nix
    ../../unison/spruce.nix
    ../../unison/suuno.nix

    # Media Server/Player
    #../../kodi.nix

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];

  # Graphical login for drive encryption
  boot.plymouth = {
    enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "macchiato";
  };

  services.hardware.openrgb.enable = true;
  hardware.graphics.enable = true;
}