{ config, lib, pkgs, ... }:
{
  virtualisation.spiceUSBRedirection.enable = true;
  environment = with pkgs; {
    systemPackages = [
      samba
      qemu
    ];
  };
}