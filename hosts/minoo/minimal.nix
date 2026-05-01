{ config, pkgs, ... }: {
  imports = [
    ../../modules/hardware/default.nix
    ../../modules/minimal.nix
    ../../modules/machine.nix
    ./machine.nix
  ];
}