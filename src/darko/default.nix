{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ../adjustlight.nix
      ../phil.nix
      ../nvidia.nix
      ../nvidia_offload.nix
    ];

  programs.kitty.fontSize = 11;
  programs.light.enable = true;

  services.auto-cpufreq.enable = true;  # TODO: Doc needed


  environment.systemPackages = with pkgs; [
    pamixer
    playerctl
  ];
}