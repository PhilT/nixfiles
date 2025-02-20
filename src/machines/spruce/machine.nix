{ config, pkgs, lib, ... }:
let
  vendor = "10de"; # Duplicated in gpu_ids.ini
  gpu = "2684";
  audio = "22ba";
  usbVendor = "";
  usbController = "";
  gpuIds = "${vendor}:${gpu},${vendor}:${audio}";
  usbControllerIds = ""; # ",${usbVendor}:${usbController}"
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

  # Ensure both displays are initialized so Plymouth can be displayed on DP-1
  boot.initrd.kernelModules = [ "i915" ];

  boot.kernelParams = [
    "intel_iommu=on"
    #"iommu=pt" # Might be needed for performance. Test and see
    #"hugepagesz=1G"
    #"hugepages=24"
  ];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=${gpuIds}${usbControllerIds}
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

  # NEW OPTIONS
  #boot.kernel.sysctl = {
  #  "vm.min_free_kbytes" = "57671680";
  #  "kernel.shmmax" = "25769803776";
  #};

  # TODO: I don't think this is needed
  #boot.blacklistedKernelModules = [
  #  "nouveau"
  #];
}