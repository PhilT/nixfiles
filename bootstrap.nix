{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices = {
    root = {
      device = "LVM_PARTITION";
      preLVM = true;
    };
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Internationalisation
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "ctrl:swapcaps";

  # User account
  users.extraUsers.phil = {
    isNormalUser = true;
    uid = 1000;
    description = "Phil Thompson";
    hashedPassword = "USER_PASSWORD";
    extraGroups = [ "wheel" "cdrom" "networkmanager" ]; # Enable ‘sudo’ for the user.
  };
  users.mutableUsers = false;

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    htop
    neovim
    wget
    which
  ];

  # Services
  services.automatic-timezoned.enable = true;

  # Security
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "23.05"; # Did you read the comment?
}

