{ config, pkgs, ... }:

# Probably won't run this on the laptop but here for reference
let
  offload_vars = ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
  '';
  #protontricksVersion = "1.10.5";
  #protontricksPname = "protontricks";
  #protontricksLatest = pkgs.protontricks.overrideAttrs ({
  #  pname = protontricksPname;
  #  version = protontricksVersion;
  #  src = pkgs.fetchFromGitHub {
  #    owner = "Matoking";
  #    repo = protontricksPname;
  #    rev = protontricksVersion;
  #    sha256 = "N9AUpHDJWhUCxXffcfNdW1TtYXMNh/Jh5kAcHovZ6iQ=";
  #  };
  #});
in
{
  programs.steam.enable = true;
  programs.gamemode.enable = true; # Run with: gamemoderun ./game, verify with: gamemoded -s

  environment = {
    systemPackages = with pkgs; [
      # (writeShellScriptBin "getSteamId" ''
      #   protontricks -l | grep $1 | sed -E 's/.*\(([0-9]+)\)/\1/'
      # '')
      # (writeShellScriptBin "rf2" ''
      #   #\${offload_vars}
      #   protontricks -c rFactor2.exe $(getSteamId rFactor)
      # '')

      # (writeShellScriptBin "rf2-config" ''
      #   #\${offload_vars}
      #   protontricks -c rF\ Config.exe $(getSteamId rFactor)
      # '')

      gamescope     # Run older games with upscaling and other options to support running on newer hardware
      lutris        # For non-steam games from other app stores or local, also supports steam games
      monado        # Open source OpenXR VR drivers with support for VR
      opencomposite # Translate OpenVR to OpenXR calls (e.g. for rFactor 2)
      xrgears       # OpenXR app for testing. Start monado with `monado-service` then run `xrgears`

      openxr-loader # Needed to run OpenXR games

      #proton-caller # Play Steam games designed to run on Windows
      #protonup-ng   # Manage Proton from commandline
#      wine          # Recommended to install via package management by lutris ** Conflicts with wineWowPackages.full
      #python3Minimal# Needed by proton-caller
    ];

      sessionVariables = {
        STEAM_DIR = "/games/steam";
        XRT_COMPOSITOR_SCALE_PERCENTAGE = "100";
        XRT_COMPOSITOR_LOG = "debug";
        XRT_LOG = "debug";
      };

    etc = {
      #"proton.conf".source = ../dotfiles/proton.conf;
      "xdg/openxr/1/active_runtime.json".source = ../dotfiles/active_runtime.json; # Monado OpenXR
      "openvr/openvrpaths.vrpath.opencomp".source = ../dotfiles/openvrpaths.vrpath.opencomp; # Opencomposite
    };
  };

  services.udev.packages = [ (pkgs.callPackage ./xrhardware.nix {}) ];

  systemd.tmpfiles.rules = [
    # Links Steam folder to /games/steam
    "L+ /home/phil/.steam/bin - - - - /games/steam/ubuntu12_32"
    "L+ /home/phil/.steam/bin32 - - - - /games/steam/ubuntu12_32"
    "L+ /home/phil/.steam/bin64 - - - - /games/steam/ubuntu12_64"
    "L+ /home/phil/.steam/root - - - - /games/steam"
    "L+ /home/phil/.steam/sdk32 - - - - /games/steam/linux32"
    "L+ /home/phil/.steam/sdk64 - - - - /games/steam/linux64"
    "L+ /home/phil/.steam/steam - - - - /games/steam"

    "d ${config.xorg.xdgConfigHome}/openvr - phil users -"
    "L+ ${config.xorg.xdgConfigHome}/openvr/openvrpaths.vrpath - - - - /etc/openvr/openvrpaths.vrpath.opencomp"
  ];

  #system.userActivationScripts.proton-ge = ''
  #  [ -e $XDG_CONFIG_HOME/proton.conf ] || ln -s /etc/proton.conf $XDG_CONFIG_HOME/proton.conf

  #  #/run/current-system/sw/bin/protonup -y -d "${compat_tools_path}"
  #  #/run/current-system/sw/bin/protonup -y -t GE-Proton7-55
  #'';
}
