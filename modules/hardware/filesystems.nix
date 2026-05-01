{ lib, config, ... }: {
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/nix" = lib.mkIf config.nixfs.enable {
    device = "/dev/disk/by-label/nix";
    fsType = "ext4";
    neededForBoot = true; # This is the default for /nix anyway
    options = [ "noatime" ]; # Reduces metadata writes, improving SSD lifespan
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" "defaults" ];
  };

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];
}