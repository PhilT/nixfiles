{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../minimal.nix
    ../../machine.nix
    ../../nvidia.nix
    ./machine.nix
  ];
}