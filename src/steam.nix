{ config, lib, pkgs, ... }: {
  # From https://github.com/Atemu/nixos-config/blob/master/modules/gaming/module.nix
  boot.kernel.sysctl = {
    # SteamOS/Fedora default, can help with performance.
    "vm.max_map_count" = 2147483642;

    # Not part of my threat model and I'd rather not have performance tank in
    # poorly coded games.
    "kernel.split_lock_mitigate" = 0;
  };

  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  programs.gamemode.enable = true;
}
