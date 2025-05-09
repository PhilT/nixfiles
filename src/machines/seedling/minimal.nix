{ config, pkgs, ... }: {
  imports = [
    ./machine.nix
    ../../minimal-configuration.nix
    ../../nvidia.nix
    ../../hardware/default.nix
  ];
}