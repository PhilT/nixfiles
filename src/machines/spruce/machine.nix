{ config, pkgs, lib, ... }:
let
  vendor = "10de"; # Duplicated in gpu_ids.ini
  gpu = "2684";
  audio = "22ba";
in {
  networking.hostId = "79ef3090";
  machine = "spruce";
  username = "phil";
  fullname = "Phil Thompson";
  time.hardwareClockInLocalTime = true;

  # TODO: Switch to ZFS
  luks.enable = true;
  luks.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA26792J_1-part2";

  fileSystems."/games" = {
    device = "/dev/disk/by-label/Games";
    fsType = "ntfs";
    options = [ "rw" "uid=1000" ];
  };

  boot.initrd.kernelModules = [
    #"nouveau" # Native resolution in early KMS (Kernel Mode Setting)
  ];
  boot.kernelParams = [
    #"nouveau.runpm=0"
    #"nvidia-drm.modeset=0" # Probably not needed as I'm not loading the propriatary Nvidia drivers

    "intel_iommu=on"
    "iommu=pt" # Might be needed for performance. Test and see
  ];

  # TODO: I don't think this is needed
#  boot.blacklistedKernelModules = [
#    "nouveau"
#  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${vendor}:${gpu},${vendor}:${audio}
  '';

  boot.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" "kvm-intel" ];

  services.udev.extraRules = ''
    KERNEL=="vfio", MODE="0660", GROUP="vfio"
    KERNEL=="vfio/*", MODE="0660", GROUP="vfio"
  '';

  # FIXME: This didn't seem to work - as in, when ignoring the LUKS password prompt on
  # the machine and trying to SSH in remotely, I got host not found.
  # Be good to test again once I've switched to ZFS
  boot.initrd.network = {
    enable = true;
    ssh.enable = true;
    ssh.hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
    ssh.authorizedKeys = [
      (builtins.readFile ../../../secrets/id_ed25519_spruce.pub)
    ];
  };
}