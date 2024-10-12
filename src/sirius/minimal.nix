{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "sirius";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/e37937eb-90df-4631-b61d-c75e46b4bce2";
}