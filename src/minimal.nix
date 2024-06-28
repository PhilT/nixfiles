# This is minimal config to get a bootable NixOS system with a single user.
# It could be used if the other configs don't boot a machine correctly into NixOS.

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware.nix  # Include the results of the hardware scan.
      ./bluetooth.nix # So devices can be added through ./initialize
    ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices.root.preLVM = true;
  boot.initrd.luks.devices."cryptroot".device = "/dev/nvme0n1p1";
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;                  # Graphical login for drive encryption
  boot.kernelParams = [ "quiet" "nosgx" ];      # Don't log boot up to screen, turn off warning about sgx
  boot.kernel.sysctl."net.core.rmem_max" = 2500000;

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    packages=[ pkgs.terminus_font ];
    font="${pkgs.terminus_font}/share/consolefonts/ter-i18b.psf.gz";
    useXkbConfig = true;
  };
  services.xserver.xkb.layout = "gb";

  users.users.phil = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = "Phil Thompson";
    hashedPassword = (builtins.readFile ../secrets/hashedPassword);
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

  system.stateVersion = "24.05"; # Did you read the comment?
}