{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "darko";
  boot.initrd.luks.devices.root.device = "/dev/nvme0n1p2";

  services.xserver.xkb.options = "ctrl:swapcaps";
}
