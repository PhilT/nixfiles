{ config, pkgs, ... }: {
  imports = [
    ../../modules/hardware/default.nix
    ../../modules/minimal.nix
    ../../modules/machine.nix
    ../../modules/nvidia.nix
    ./machine.nix
  ];
}