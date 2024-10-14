{ config, pkgs, ... }: {
  imports = [
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../minimal.nix
  ];

  username = "phil";
  fullname = "Phil Thompson";
  networking.hostName = "aramid";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/${builtins.readFile ./luks_uuid}";
}