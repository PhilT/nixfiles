{ config, pkgs, ... }:

{
  imports = [ ../minimal.nix ];

  networking.hostName = "spruce";
  boot.initrd.kernelModules = [ "nouveau" ]; # Native resolution in early KMS (Kernel Mode Setting)
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/59220a00-1da3-400b-a61e-0e26a8fccb37";
  time.hardwareClockInLocalTime = true; # Ensure dual booting Windows does not cause incorrect time # FIXME: This isn't working, Windows is still an hour behind

  fileSystems."/games" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" ];
  };
}