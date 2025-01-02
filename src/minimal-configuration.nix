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
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_12;

  # Pin to an older linux version when current NixOS one is incompatible with ZFS
  # boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_6.override {
  #   argsOverride = rec {
  #     src = pkgs.fetchurl {
  #           url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
  #           sha256 = "sha256-VeW8vGjWZ3b8RolikfCiSES+tXgXNFqFTWXj0FX6Qj4=";
  #     };
  #     version = "6.10.14";
  #     modDirVersion = "6.10.14";
  #   };
  # });

  boot.extraModulePackages = with config.boot.kernelPackages; [];

  networking.hostName = config.machine;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [];
  networking.networkmanager.wifi.backend = "iwd";
  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile ../secrets/hashed_password);
    extraGroups = [ "wheel" "users" "docker" "networkmanager" "audio" "video" ];
  };
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    nix-output-monitor    # Fancy output for nixos-rebuild

    htop
    wget
    which
    curl
    keepassxc
    git
  ];
}