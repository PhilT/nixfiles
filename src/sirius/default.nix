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
    # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)
    auto-cpufreq.enable = true;

    syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";
  };

  programs.kitty.fontSize = 11;
  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    (callPackage ../iio-hyprland.nix {})
    flashrom
    pamixer
    playerctl
  ];
}