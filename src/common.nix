{ config, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./audio.nix
    ./browser.nix
    ./carwow.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./neovim.nix
    ./syncthing.nix
    ./tmux.nix
    ./programs.nix
    ./xserver.nix
  ];

  virtualisation.docker.enable = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  services = {
    # Only seems to work after opening PCManFM
    gvfs.enable = true; # Automount USB drives
  };
}
