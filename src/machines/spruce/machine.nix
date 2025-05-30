{ config, pkgs, lib, ... }: {
  networking.hostId = "79ef3090";
  machine = "spruce";
  username = "phil";
  fullname = "Phil Thompson";
  #persistedHomeDir = "${config.dataDir}/home";
  persistedMachineDir = "${config.dataDir}/machine";

  # TODO: Switch to ZFS
  luks.enable = true;
  luks.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TA26792J_1-part2";

# Causes NixOS to get into a non-boot state if the drive isn't unmounted correctly which
# happens quite a bit when using as a VM. So safer to remove it.
#  fileSystems."/games" = {
#    device = "/dev/disk/by-label/Games";
#    fsType = "ntfs";
#    options = [ "rw" "uid=1000" ];
#  };

  boot.initrd.kernelModules = [
    "i915"        # Ensure both displays are initialized so Plymouth can be displayed
    "dm-snapshot" # Used by Spruce (Can be removed when switching to ZFS)
  ];

  boot.kernel.sysctl = {
    "vm.transparent_hugepages" = "always"; # Better performance for Gaming in VMs
  };

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