{ config, pkgs, ... }: {
  networking.hostId = "79ef3090";
  machine = "spruce";
  username = "phil";
  fullname = "Phil Thompson";
  time.hardwareClockInLocalTime = true;

  luks.enable = true;
  luks.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA26792J_1-part2";

  fileSystems."/games" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" ];
  };

  # Needed for Nouveau, but ZFS doesn't support 6.11 yet
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11;
  boot.initrd.kernelModules = [ "nouveau" ]; # Native resolution in early KMS (Kernel Mode Setting)
  boot.kernelParams = [ "nouveau.runpm=0" ];
}