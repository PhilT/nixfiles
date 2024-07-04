{ config, pkgs, ... }:

{
  imports = [
    ./minimal.nix
    ./hypridle.nix

    ../gaming.nix
    ../phil.nix
    ../nvidia.nix
  ];

  services.syncthing.key = "${../../secrets/spruce/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/spruce/syncthing.cert.pem}";
  services.hardware.openrgb.enable = true;

  environment.etc = {
    "xdg/hypr/machine.conf".source = ../../dotfiles/hyprland-spruce.conf;
  };
  environment.systemPackages = with pkgs; [
    ddcutil               # Control external monitor brightness

    (writeShellScriptBin "monlight" ''
      if [[ "$1" == "up" ]]; then
        amount=50
      elif [[ "$1" == "down" ]]; then
        amount=5
      else
        exit 1
      fi

      ddcutil setvcp 10 $amount --bus 5 &
      ddcutil setvcp 10 $amount --bus 6 &
    '')
  ];

  programs.kitty.fontSize = 10;
}