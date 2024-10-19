{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../minimal-configuration.nix
    ./machine.nix
  ];
}
