{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../minimal-configuration.nix
    ../../machine.nix
    ../../nvidia.nix
    ./machine.nix
  ];
}