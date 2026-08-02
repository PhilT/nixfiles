# To pair a device on both NixOS and Windows (spruce):
# 1. Pair the device on NixOS.
# 2. Reboot into Windows and pair it there too.
# 3. Back on NixOS: sudo bt-sync-windows
# See modules/scripts/bt-sync-windows.nix for how it works.
{ config, pkgs, ... }: {
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      AutoEnable = true;
    };
  };
}