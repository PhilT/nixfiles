{ config, pkgs, lib, ... }: {
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