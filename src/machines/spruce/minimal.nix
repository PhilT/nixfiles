{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../minimal.nix
    ../../machine.nix
    ./machine.nix
  ];
}