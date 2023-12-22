# The Steam client will be downloaded or updated at ~/.local/share/Steam by default.

{ config, pkgs, ... }:

# Probably won't run this on the laptop but here for reference
let
  offload_vars = ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
  '';
in
{
  nixpkgs.config.allowUnfree = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true; # Run with: gamemoderun ./game, verify with: gamemoded -s

  environment = {
    systemPackages = with pkgs; [
      game-devices-udev-rules # Udev rules to make controllers available with non-sudo permissions
      lutris        # For non-steam games from other app stores or local, also supports steam games
      busybox                 # Starwars Squadrons needs lsusb
    ];
  };

  systemd.tmpfiles.rules = [
    "L+ /home/phil/.local/share/Steam/steamapps - - - - /games/steam/steamapps"
  ];
}