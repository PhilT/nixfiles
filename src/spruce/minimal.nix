{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "spruce";
  boot.initrd.luks.devices.root.device = "/dev/nvme1n1p2";
  time.hardwareClockInLocalTime = true; # Ensure dual booting Windows does not cause incorrect time

  fileSystems."/games" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" ];
  };
}