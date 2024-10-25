{ config, lib, pkgs, ... }: {
  imports = [
    ./machine.nix
    ../../minimal-configuration.nix
    ../../hardware/default.nix
    ../../hardware/bluetooth.nix
    ../../common.nix
    ../../development.nix

    # Sync
    # ?

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];
}