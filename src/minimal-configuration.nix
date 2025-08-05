{ config, lib, pkgs, ... }: {
  imports = [ ./options.nix ];

  system.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      timeout = 0; # Use SPACE to override
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd.luks.devices = lib.mkIf config.luks.enable {
      root.device = config.luks.device;
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_6_15;
    extraModulePackages = with config.boot.kernelPackages; [];
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

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

  programs.fish.enable = true;                # Fish! Shell
  documentation.man.generateCaches = false;   # Stops painfully slow builds when using Fish
  networking.hostName = config.machine;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [];
  networking.networkmanager.wifi.backend = "iwd";
  users.groups.fuse = {}; # TODO: Confirm whether this is needed (in extraGroups as well)
  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile ../secrets/hashed_password);
    extraGroups = [
      "audio"
      "docker"
      "fuse"
      "networkmanager"
      "users"
      "video"
      "wheel"
    ];
    shell = pkgs.fish;
  };
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [ "ntp.3eck.net" "nts1.adopo.net" "time.cloudflare.com" ];
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor    # Fancy output for nixos-rebuild

    htop
    wget
    which
    curl
    keepassxc
    git
    ruby_3_4              # Needed for nixfiles
  ];
}