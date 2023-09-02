# This is minimal config to get a bootable NixOS system with a single user.
# It could be used if the other configs don't boot a machine correctly into NixOS.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
    ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.root.preLVM = true;
  boot.initrd.luks.devices = {
    root = {
      device = (builtins.readFile ./secrets/${hostname}/device);
      preLVM = true;
    };
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "ctrl:swapcaps";

  users.users.phil = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = "Phil Thompson";
    hashedPassword = (builtins.readFile ./secrets/hashedPassword);
    extraGroups = [ "wheel" "docker" "networkmanager" "audio" "video" ];
  };
  users.mutableUsers = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  environment.systemPackages = with pkgs; [
    htop
    wget
    which
  ];

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "23.05"; # Did you read the comment?
}

