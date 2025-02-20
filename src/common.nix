{ config, lib, pkgs, ... }:
{
  imports = [
    ./audio.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./mimetypes.nix
    ./neovim.nix
    ./programs.nix
    ./ranger.nix
    ./tmux.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    # Remove unused derivations periodically
    gc.automatic = true;
    gc.dates = "weekly";

    # Optimise (cleanup) the Nix store periodically
    optimise.automatic = true;
    optimise.dates = [ "12:30" ];

    # @wheel means all users in the wheel group
    settings.trusted-users = [
      config.username
      "root"
      "@wheel"
    ];
  };

  boot = {
    initrd = {
      verbose = false;
      systemd.enable = true;
    };

    kernelParams = [
      "quiet"         # Don't log boot up to screen
      "nosgx"         # Turn off warning about sgx
    ];
  };

  console = {
    packages= with pkgs;[ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
    useXkbConfig = true;
  };

  fonts.packages = with pkgs; [ meslo-lgs-nf ];
  services.kmscon = {
    enable = true;
    hwRender = true;
    extraConfig = ''
      font-name=MesloGS NF
      font-size=14
    '';
  };

  # This only works in a console
  # See dotfiles/sway/config for GUI setting
  services.xserver.xkb = {
    layout = "gb";
    options = "ctrl:nocaps";
  };

  environment.enableAllTerminfo = true;

  # DHCP Reservations setup on Linksys Router
  # Used mainly for Unison sync and SSH
  networking.hosts = {
    "192.168.1.87" = [ "aramid" ];
    "192.168.1.248" = [ "minoo" ];
    "192.168.1.226" = [ "spruce" ];
    "192.168.1.205" = [ "suuno" ];
    "192.168.1.100" = [ "sapling" ];
    "192.168.1.101" = [ "seedling" ];
  };
}