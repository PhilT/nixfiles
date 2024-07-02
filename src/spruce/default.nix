{ config, pkgs, ... }:

{
  imports = [
    ./minimal.nix

    ../gaming.nix
    ../phil.nix
    ../nvidia.nix
  ];

  services.syncthing.key = "${../../secrets/spruce/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/spruce/syncthing.cert.pem}";

  environment.etc = {
    "xdg/hypr/machine.conf".source = ../../dotfiles/hyprland-spruce.conf;
  };

  programs.kitty.fontSize = 10;
}