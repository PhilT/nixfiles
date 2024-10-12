{ config, pkgs, ... }:

{
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    ../minimal.nix
  ];

  networking.hostName = "aramid";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/<REPLACE WITH UUID>";
}