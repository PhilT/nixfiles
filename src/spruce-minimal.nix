{ config, pkgs, ... }:

{
  imports = [ ./minimal.nix ];

  networking.hostName = "spruce";
  boot.initrd.luks.devices.root.device = "/dev/nvme0n2p2";
}

