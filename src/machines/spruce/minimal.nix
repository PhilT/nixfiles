{ config, pkgs, ... }:

{
  imports = [
    ./machine.nix
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../minimal-configuration.nix
  ];
}