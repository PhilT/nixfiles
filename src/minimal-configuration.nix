{ config, lib, pkgs, ... }: {
  imports = [ ./options.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "24.05";

  boot.initrd.luks.devices = lib.mkIf config.luks.enable {
    root.device = config.luks.device;
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Latest ZFS supported kernel. Support for 6.11 in RC (https://github.com/openzfs/zfs/releases)
  # 6.10 is out of support so no longer included in NixOS. Therefore need to revert to LTS kernel.
  # Overridden in spruce as 6.11 currently needed for Nouveau drivers.
  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11;
  boot.extraModulePackages = with config.boot.kernelPackages; [];

  networking.hostName = config.machine;
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile ../secrets/hashed_password);
    extraGroups = [ "wheel" "docker" "networkmanager" "audio" "video" ];
  };
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    htop
    wget
    which
    curl
    keepassxc
    git
  ];
}