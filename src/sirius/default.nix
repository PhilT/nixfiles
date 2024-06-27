{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ../phil.nix
      ../adjustlight.nix
    ];

  programs.kitty.fontSize = 11;

  services = {
    auto-cpufreq.enable = true;  # CPU power/speed optimiser (https://github.com/AdnanHodzic/auto-cpufreq)

    syncthing.key = "${../../secrets/sirius/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/sirius/syncthing.cert.pem}";
  };

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    pamixer
    playerctl
  ];
}