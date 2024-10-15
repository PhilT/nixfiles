{ config, pkgs, ... }: {
  imports = [
    /mnt/etc/nixos/hardware-configuration.nix
    ../../minimal-configuration.nix
    ./machine.nix
  ];
}