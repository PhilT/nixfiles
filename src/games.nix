# To allow SteamVR to work the following command needs to be run the first time:
#   sudo setcap CAP_SYS_NICE+ep ~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
# https://lvra.gitlab.io/docs/other/bigscreen-beyond-driver/
# C:\\Program Files (x86)\\Steam\\steamapps\\common\\SteamVR

{ config, lib, pkgs, ... }: {
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  environment.systemPackages = with pkgs;[
    qemu
    steamcmd
  ];

# The following allows Simagic Alpha U to work in Windows. More specifically
# it enables VFIO passthrough for the USB controller the Alpha U is connected to.
# However, we're planning to sell the Simagic kit so probably won't need this.
#  boot.kernelParams = [
#    "intel_iommu=on"
#    "iommu=pt"          # Performance tweak
#  ];
#
#  boot.kernelModules = [
#    "vfio_pci"
#    "vfio_iommu_type1"
#    "vfio_virqfd"
#    "vfio"
#    "kvm-intel"
#  ];
#
#  security.pam.loginLimits = [
#    {
#      domain = "*";
#      type = "-";
#      item = "memlock";
#      value = "infinity";
#    }
#  ];
#
#  # These rules only apply to connected devices. E.g. If my wheel is off it won't apply the permissions
#  # This requires Sway to be started as a systemd service so that it's managed properly
#  services.udev.extraRules = ''
#    SUBSYSTEM=="vfio", TAG+="uaccess"
#    SUBSYSTEM=="usb", TAG+="uaccess"
#  '';
#
#  users.groups.vfio = {};
#  users.groups.hugepages = {};
#  users.users."${config.username}".extraGroups = [
#    "kvm"
#    "vfio"
#  ];
}