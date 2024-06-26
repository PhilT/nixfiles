{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "sirius";
  boot.initrd.luks.devices.root.device = "/dev/nvme0n1p2";
}