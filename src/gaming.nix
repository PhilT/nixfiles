{ config, pkgs, ... }:

{
  programs.steam.enable = true;

  environment = {
    sessionVariables = rec {
      STEAM_COMPAT = "/home/phil/.steam/root/compatibilitytools.d";
      STEAM_COMMON = "/home/phil/.steam/steam/steamapps/common";
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "rf2" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only

        proton-call -r rFactor2.exe
      '')

      (writeShellScriptBin "rf2-config" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only

        proton-call -r rF\ Config.exe
      '')

      lutris        # For non-steam games from other app stores or local
      monado        # Open source OpenXR VR drivers with support for VR
      proton-caller # Play Steam games designed to run on Windows
      protonup-ng   # Manage Proton from commandline
      wine          # Recommended to install via package management by lutris
      python3Minimal# Needed by proton-caller
    ];

    etc = {
      "proton.conf".source = ../dotfiles/proton.conf; # TODO: Move to gaming.nix
    };
  };

  system.userActivationScripts.proton-ge = ''
    [ -e $XDG_CONFIG_HOME/proton.conf ] || ln -s /etc/proton.conf $XDG_CONFIG_HOME/proton.conf

    /run/current-system/sw/bin/protonup -y
    /run/current-system/sw/bin/protonup -y -t GE-Proton7-55
  '';
}
