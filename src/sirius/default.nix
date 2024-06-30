{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ../adjustlight.nix
      ../phil.nix
    ];

  hardware.sensor.iio.enable = true;

  services = {
    auto-cpufreq.enable = true;  # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)

    syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";
  };

  programs = {
    kitty.fontSize = 11;
    light.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (callPackage ../iio-hyprland.nix {})
    flashrom
    pamixer
    playerctl
  ];
}