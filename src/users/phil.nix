{ config, pkgs, ... }:
{
  username = "phil";
  fullname = "Phil Thompson";

  # Support for Ploopy trackball (and supposedly GMMK 2 but isn't currently working)
  hardware.keyboard.qmk.enable = true;
  virtualisation.docker.enable = true;

  environment.systemPackages = with pkgs; [
    overskride                              # Bluetooth GUI
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
        config.username
        "root"
        "@wheel"
      ];
    };
  };
}