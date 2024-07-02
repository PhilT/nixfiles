{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ../adjustlight.nix
      ../phil.nix
    ];

  hardware.sensor.iio.enable = true;

  # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)
  services.auto-cpufreq.enable = true;

  services.syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
  services.syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";

  environment.etc = {
    "xdg/hypr/machine.conf".source = ../../dotfiles/hyprland-sirius.conf;
  };

  environment.systemPackages = with pkgs; [
    (callPackage ../iio-hyprland.nix {})
    flashrom
    pamixer
    playerctl
  ];

  programs.kitty.fontSize = 11;
  programs.light.enable = true;
}