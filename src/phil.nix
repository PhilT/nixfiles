{ config, pkgs, ... }:

{
  imports = [
    ../secrets/work.nix
    ./kitty.nix
    ./audio.nix
    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./keepmenu.nix
    ./hyprland.nix
    ./neovim.nix
    ./programs.nix
    ./syncthing.nix
    ./thunderbird.nix
    ./tmux.nix
  ];

  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
    devenv
  ];
  users.users.phil.extraGroups = [ "docker" ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "phil"
        "@wheel"
      ];
    };
  };

  services = {
    # Automount USB drives
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };
}