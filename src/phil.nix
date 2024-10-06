{ config, pkgs, ... }:

{
  imports = [
    ../secrets/work.nix
    ./kitty.nix
    ./audio.nix
    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./qutebrowser.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./keepmenu.nix
    ./sway.nix
    ./neovim.nix
    ./programs.nix
    ./thunderbird.nix
    ./tmux.nix
  ];

  hardware.keyboard.qmk.enable = true; # Support for Ploopy trackball (and supposedly GMMK 2 but isn't currently working)
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    docker-compose
    devenv
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      auto-optimise-store = true;

      # @wheel means all users in the wheel group
      trusted-users = [
        "root"
        "phil"
        "@wheel"
      ];
    };
  };
}