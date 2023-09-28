{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "spruce";
  boot.initrd.luks.devices.root.device = "/dev/nvme2n1p2";

  fileSystems."/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "ext4";
  };
}

