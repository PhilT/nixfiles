{ config, pkgs, ... }:

{
  imports = [
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../minimal.nix
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
  ];

  networking.hostName = "aramid";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/<REPLACE WITH UUID>";
}