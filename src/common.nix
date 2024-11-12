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

  boot.initrd.systemd.enable = true;

  # Don't log boot up to screen, turn off warning about sgx
  boot.kernelParams = [ "quiet" "nosgx" ];

  console = {
    packages=[ pkgs.terminus_font ];
    font="${pkgs.terminus_font}/share/consolefonts/ter-i18b.psf.gz";
    useXkbConfig = true;
  };

  # This only works in a console
  # See dotfiles/sway/config for GUI setting
  services.xserver.xkb = {
    layout = "gb";
    options = "ctrl:nocaps";
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  environment.enableAllTerminfo = true;

  # DHCP Reservations setup on Linksys Router
  # Used mainly for Unison sync and SSH
  networking.hosts = {
    "192.168.1.87" = [ "aramid" ];
    "192.168.1.248" = [ "minoo" ];
    "192.168.1.226" = [ "spruce" ];
    "192.168.1.205" = [ "suuno" ];
  };
}