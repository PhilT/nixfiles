# Copied from hardware-configuration.nix
# Modified to use disk/by-label
# Machine specific config to be moved to machines/<machine_name>.nix

{ config, lib, pkgs, ... }:
{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "rtsx_pci_sdmmc"
    "usb_storage"
    "sd_mod"
    "thunderbolt"
    "aesni_intel"
    "cryptd"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" "i2c_dev" ];
  # boot.kernelParams = [ "iomem=relaxed" ]; # Needed when flashing rom

  boot.kernelPackages = pkgs.linuxPackages_latest;
#  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11; # If you want to use a specific version instead of latest above
  boot.extraModulePackages = with config.boot.kernelPackages; [];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.docker0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp8s0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  #powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # I think this causes issues with cursor disappearing on Sirius
  # hardware.logitech.wireless.enable = true;
  # hardware.logitech.wireless.enableGraphical = true;
}