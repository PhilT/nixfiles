{ config, lib, pkgs, ... }: {
  boot.kernelParams = [
    # Turn off Variable Refresh Rate (VRR) support for NVIDIA as we don't have VRR monitors
    # This can help with screen tearing as it uses ULMB (Ultra Low Motion Blur).
    "nvidia-modeset.conceal_vrr_caps=1"
  ];

  # From https://github.com/Atemu/nixos-config/blob/master/modules/gaming/module.nix
  boot.kernel.sysctl = {
    # SteamOS/Fedora default, can help with performance.
    "vm.max_map_count" = 2147483642;

    # Not part of my threat model and I'd rather not have performance tank in
    # poorly coded games.
    "kernel.split_lock_mitigate" = 0;
  };

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
}