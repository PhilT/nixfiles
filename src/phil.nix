{ config, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./audio.nix
    ./firefox.nix
    ./carwow.nix
    ./environment.nix
    ./fonts.nix
    ./gaming.nix
    ./git.nix
    ./neomutt.nix
    ./neovim.nix
    ./programs.nix
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

  environment.systemPackages = with pkgs; [
    (callPackage ./studio.nix {})

    wineWowPackages.full # Needed for FL Studdio installer
  ];
}