{ config, pkgs, ... }:

# https://linuxhint.com/how-to-instal-steam-on-nixos/

# Probably won't run this one the laptop but here for reference
let offload_vars = ''
  export __NV_PRIME_RENDER_OFFLOAD=1
  export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export __VK_LAYER_NV_optimus=NVIDIA_only
'';
  compat_tools_path = "/games/steam/root/compatibilitytools.d";
in
{
  programs.steam.enable = true;
  programs.gamemode.enable = true; # Run with: gamemoderun ./game, verify with: gamemoded -s

  environment = {
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = compat_tools_path;
      STEAM_COMMON = "/games/steam/steamapps/common";
    };

    systemPackages = with pkgs; [
      (writeShellScriptBin "rf2" ''
        #\${offload_vars}
        proton-call -r rFactor2.exe
      '')

      (writeShellScriptBin "rf2-config" ''
        #\${offload_vars}
        proton-call -r rF\ Config.exe
      '')

      lutris        # For non-steam games from other app stores or local
      monado        # Open source OpenXR VR drivers with support for VR
      proton-caller # Play Steam games designed to run on Windows
      protonup-ng   # Manage Proton from commandline
#      wine          # Recommended to install via package management by lutris ** Conflicts with wineWowPackages.full
      python3Minimal# Needed by proton-caller
    ];

    etc = {
      "proton.conf".source = ../dotfiles/proton.conf;
    };
  };

  system.userActivationScripts.proton-ge = ''
    [ -e $XDG_CONFIG_HOME/proton.conf ] || ln -s /etc/proton.conf $XDG_CONFIG_HOME/proton.conf

    #/run/current-system/sw/bin/protonup -y -d "${compat_tools_path}"
    #/run/current-system/sw/bin/protonup -y -t GE-Proton7-55
  '';
}
