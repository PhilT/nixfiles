# This is minimal config to get a bootable NixOS system with a single user.
# It's used by ./bootstrap to build the first generation config for the target machine.
# It could also be used if the other configs don't boot a machine correctly into NixOS.

{ config, pkgs, ... }:
{
  imports = [ ./options.nix ];

  # Fix nose not being supported by Python 3.12
  nixpkgs.overlays = [
    (_: prev: {
        python312 = prev.python312.override { packageOverrides = _: pysuper: { nose = pysuper.pynose; }; };
    })
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      auto-optimise-store = true;

      # @wheel means all users in the wheel group
      trusted-users = [
        config.username
        "root"
        "@wheel"
      ];
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;

  # Don't log boot up to screen, turn off warning about sgx
  boot.kernelParams = [ "quiet" "nosgx" ];
  boot.kernel.sysctl."net.core.rmem_max" = 2500000; # FIXME: What's this for?

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

  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile ../secrets/hashed_password);
    extraGroups = [ "wheel" "docker" "networkmanager" "audio" "video" ];
  };
  users.mutableUsers = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    htop
    wget
    which
  ];

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.05"; # Did you read the comment?
}