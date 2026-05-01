{ config, lib, pkgs, ... }: {
  imports = [
    ./base.nix
    ./options.nix
  ];

  system.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      timeout = 0; # Use SPACE to override
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Enable systemd in initrd for better shutdown handling of encrypted devices
    initrd.systemd.enable = true;

    initrd.luks.devices = lib.mkIf config.luks.enable {
      root = {
        device = config.luks.device;
        # Tell systemd this device is managed by initrd and shouldn't be detached during shutdown
        # This fixes the 20-30s shutdown delay with systemd 257+
        # See: https://github.com/systemd/systemd/issues/14224
        crypttabExtraOpts = [ "x-initrd.attach" ];
      };
    };

    extraModulePackages = with config.boot.kernelPackages; [];
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

  # Pin to an older linux version not available in nixpkgs. Sometimes useful
  #boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_6.override {
  #  argsOverride = rec {
  #    src = pkgs.fetchurl {
  #          url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
  #          sha256 = "sha256-qwa7qIUeS2guiDT2+Q5W0y3PmNjGLNU3Z2EEz9dXqPI=";
  #    };
  #    # See: https://forum.manjaro.org/t/shutdown-problem-with-kernels-6-15-and-6-16/179384
  #    # Problems with kernel 6.17 and nvidia drivers
  #    version = "6.16.10";
  #    modDirVersion = "6.16.10";
  #  };
  #});

  programs.fish.enable = true;                # Fish! Shell
  programs.fish.package = pkgs.fish.override { usePython = false; };
  documentation.man.generateCaches = false;   # Stops painfully slow builds when using Fish
  networking.hostName = config.machine;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [];
  networking.networkmanager.wifi.backend = "iwd";

  # Speed up shutdown - reduce NetworkManager stop timeout (normally takes <1s)
  systemd.services.NetworkManager.serviceConfig.TimeoutStopSec = "10s";
  users.groups.fuse = {}; # TODO: Confirm whether this is needed (in extraGroups as well)
  users.groups.plugdev = {}; # Needed for ZSA Voyager udev rules (common_gui.nix)
  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile /tmp/hashed_password);
    extraGroups = [
      "audio"
      "docker"
      "plugdev"
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

    keepassxc
  ];

  systemd.tmpfiles.rules = [
    "L+ ${config.homeDir}/.config/fish - - - - ${config.persistedHomeDir}/config/fish"
  ];
}