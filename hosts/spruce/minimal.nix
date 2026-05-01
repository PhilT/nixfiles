{ config, pkgs, ... }: {
  imports = [
    ../../modules/hardware/default.nix
    ../../modules/hardware/filesystems.nix
    ../../modules/minimal.nix
    ../../modules/machine.nix
    ../../modules/nvidia.nix
    ./machine.nix
  ];
}