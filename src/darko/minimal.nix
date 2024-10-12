{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "darko";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/<REPLACE WITH UUID>";
}