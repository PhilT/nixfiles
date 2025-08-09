{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../minimal.nix
    ../../machine.nix
    ./machine.nix
  ];
}