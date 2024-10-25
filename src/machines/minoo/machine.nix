{ config, lib, pkgs, ... }:
# let
#   usbkey_id = "usb-USB_SanDisk_3.2Gen1_01016f2ec64abfae1c29851a472748a675e424c71341eaac5d4cf3b8fd6a219a098000000000000000000000e58a12c6ff96500083558107b62efe34-0:0";
#   usbdata_uuid = "d3977711-cc51-4680-a179-9fe815184fcd";
#   usbdata_id = "usb-SanDisk_Extreme_55AE_32343133464E343032383531-0:0-part1";
# in
{
  networking.hostId = "badbe6b6";
  machine = "minoo";
  username = "phil";
  fullname = "Phil Thompson";
}