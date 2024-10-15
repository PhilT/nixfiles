# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <catppuccin/modules/nixos>

    ./machine.nix
    ../../minimal-configuration.nix
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../common.nix

    # Sync
    ../../ssh.nix
    ../../unison/spruce.nix
    ../../unison/suuno.nix
  ];

  # Graphical login for drive encryption
  boot.plymouth = {
    enable = true;
    catppuccin.enable = true;
    catppuccin.flavor = "macchiato";
  };
}