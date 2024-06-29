{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ./adjustlight.nix
      ../phil.nix
    ];

  services = {
    auto-cpufreq.enable = true;  # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)

    syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";
  };

  programs = {
    kitty.fontSize = 9;
    light.enable = true;
  };

  environment.systemPackages = with pkgs; [
    flashrom
    pamixer
    playerctl
  ];
}