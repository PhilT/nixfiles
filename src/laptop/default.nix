{ config, lib, pkgs, ... }:
{
  # CPU power/speed optimiser https://github.com/AdnanHodzic/auto-cpufreq
  services.auto-cpufreq.enable = true;

  programs.kitty.fontSize = 9;

  environment.systemPackages = with pkgs; [
    pamixer           # Control volume with laptop media keys
    playerctl         # Control playback with laptop media keys
  ];
}
