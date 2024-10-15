{ config, lib, pkgs, ... }: {
  imports = [ ./options.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "24.05";

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11; # If you want to use a specific version instead of latest above
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
}