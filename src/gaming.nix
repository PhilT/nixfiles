# To allow SteamVR to work the following command needs to be run the first time:
#   sudo setcap CAP_SYS_NICE+ep /mnt/games/Steam/steamapps/common/SteamVR/bin/linux64/vrcompositor-launcher
# https://lvra.gitlab.io/docs/other/bigscreen-beyond-driver/
# C:\\Program Files (x86)\\Steam\\steamapps\\common\\SteamVR

{ config, lib, pkgs, ... }: {
  # Udev rules for Bigscreen Beyond
  services.udev.extraRules = ''
    # Bigscreen Beyond HMD
    ACTION=="add", KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35bd", ATTRS{idProduct}=="0101", TAG+="uaccess", MODE="0660"
  '';

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  environment.systemPackages = with pkgs;[
    ntfs3g   # Write access to NTFS partitions for Steam
    qemu
    steamcmd # Used to download Windows SteamVR (~/steamvr_win). Might not need though.
  ];

  # Mount NTFS Games drive at boot
  systemd.services.mount-games = {
    description = "Mount NTFS Games Drive";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /mnt/games";
      ExecStart = "${pkgs.ntfs3g}/bin/ntfs-3g /dev/disk/by-uuid/B272444F72441A8D /mnt/games -o uid=1000,gid=100,rw";
      ExecStop = "${pkgs.util-linux}/bin/umount /mnt/games";
      TimeoutStopSec = "10s";
    };
  };

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