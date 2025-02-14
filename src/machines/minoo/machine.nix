{ config, lib, pkgs, ... }:
# let
#   usbkey_id = "usb-USB_SanDisk_3.2Gen1_01016f2ec64abfae1c29851a472748a675e424c71341eaac5d4cf3b8fd6a219a098000000000000000000000e58a12c6ff96500083558107b62efe34-0:0";
#   usbdata_uuid = "d3977711-cc51-4680-a179-9fe815184fcd";
#   usbdata_id = "usb-SanDisk_Extreme_55AE_32343133464E343032383531-0:0-part1";
# in
{
  machine = "minoo";
  username = "phil";
  fullname = "Phil Thompson";
  nixfs.enable = true;

  networking.hostId = "badbe6b6";

  # Should probably move this out of machine specific config
  boot.kernelParams = [ "nohibernate" ];  # Hibernate not supported on ZFS (no swapfiles)
  boot.supportedFilesystems = [ "zfs" ];
  services.zfs.autoScrub.enable = true;   # Setup a scrub schedule
  boot.zfs.forceImportRoot = false;       # Hopefully don't need backwards compatibility
  boot.zfs.devNodes = "/dev/disk/by-id";

  fileSystems = {
    "/" = {
      device = "zpool/root";
      fsType = "zfs";
    };

    "/nix" = {
      device = "zpool/nix";
      fsType = "zfs";
    };

    "/data" = {
      device = "dpool/data";
      fsType = "zfs";
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" "defaults" ];
    };
  };
}