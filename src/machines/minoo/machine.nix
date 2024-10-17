{ config, lib, pkgs, ... }:
let
  usbkey_id = "usb-USB_SanDisk_3.2Gen1_01016f2ec64abfae1c29851a472748a675e424c71341eaac5d4cf3b8fd6a219a098000000000000000000000e58a12c6ff96500083558107b62efe34-0:0";
in
{
  machine = "minoo";
  username = "phil";
  fullname = "Phil Thompson";
  nixfs.enable = true;

  boot.initrd.luks.devices = lib.mkIf config.luks.enable {
    root = {
      allowDiscards = true;
      keyFileSize = 4096;
      keyFile = "/dev/disk/by-id/${usbkey_id}";
    };
  };
}