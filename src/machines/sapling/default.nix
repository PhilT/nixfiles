{ config, lib, pkgs, ... }: {
  imports = [
    ./minimal.nix

    # User
    ../../users/phil.nix

    # Sync
    # ?

    # Desktop
    ../../desktop/default.nix
    ../../desktop/light.nix
  ];

  config = {
  };
}