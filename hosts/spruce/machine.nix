{ config, pkgs, lib, ... }: {
  networking.hostId = "79ef3090";
  machine = "spruce";
  username = "phil";
  fullname = "Phil Thompson";
  persistedHomeDir = "${config.dataDir}/home";
  persistedMachineDir = "${config.dataDir}/machine";
  swayOptions = "--unsupported-gpu"; # Needed for Nvidia proprietary drivers

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
    "dm-snapshot" # Used by Spruce (Can be removed when switching to ZFS)
  ];

  boot.kernel.sysctl = {
    "vm.transparent_hugepages" = "always"; # Better performance for Gaming in VMs
  };

  # FIXME: Remote LUKS unlock via SSH - hasn't been tested successfully yet.
  # With systemd stage 1, cryptsetup-askpass is not available. The approach is:
  # ssh <host> -o RequestTTY=force, then run `systemctl default`.
  # TODO: May also need boot.initrd.systemd.network instead of boot.initrd.network once on ZFS.
  boot.initrd.network = {
    enable = true;
    ssh.enable = true;
    ssh.hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
    ssh.authorizedKeys = [
      (builtins.readFile ../../secrets/id_ed25519_spruce.pub)
    ];
  };
}