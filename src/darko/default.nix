{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ../phil.nix
      ../adjustlight.nix
      ../nvidia.nix
      ../nvidia_offload.nix
    ];

  programs.kitty.fontSize = 11;

  services = {
    auto-cpufreq.enable = true;  # TODO: Doc needed

    syncthing.key = "${../../secrets/darko/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/darko/syncthing.cert.pem}";
  };

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
    pamixer
    playerctl
  ];
}