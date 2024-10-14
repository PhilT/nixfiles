{ config, pkgs, ... }:

{
  imports = [
    ../../hardware/default.nix
    ../../hardware/filesystems.nix
    ../../hardware/bluetooth.nix
    ../../minimal.nix
  ];

  username = "phil";
  fullname = "Phil Thompson";
  networking.hostName = "spruce";
  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/59220a00-1da3-400b-a61e-0e26a8fb37";

  # Ensure dual booting Windows does not cause incorrect time
  # FIXME: This isn't working, Windows is still an hour behind, sometimes
  time.hardwareClockInLocalTime = true;

  fileSystems."/games" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" ];
  };

  boot.initrd.kernelModules = [ "nouveau" ]; # Native resolution in early KMS (Kernel Mode Setting)
  boot.kernelParams = [ "nouveau.runpm=0" ];
}