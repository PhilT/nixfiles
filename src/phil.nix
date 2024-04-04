{ config, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./kitty.nix
    ./audio.nix
    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./keepmenu.nix
    ./himalaya.nix
    #./neomutt.nix
    ./neovim.nix
    ./programs.nix
    ./ruby.nix
    ./syncthing.nix
    ./tmux.nix
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
    # Automount USB drives
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };
}