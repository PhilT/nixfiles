{ config, pkgs, ... }:

{
  imports = [
    ./bootstrap.nix
  ];

  # Environment variables
  environment.sessionVariables = rec {
    CODE_DIR = "$HOME/code";
  };

  # Enable the X11 windowing system
  services = {
    xserver = {
      enable = true;
      layout = "gb";
      libinput.enable = true; # Touchpad support
      displayManager = {
	lightdm.enable = false;
        startx.enable = true;
      };
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = builtins.fetchGit {
          url = "https://github.com/PhilT/dwm.git";
          ref = "main"; # Could move this to machine specific config to have diff configs
        };
      };
    };
  };

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    dmenu
    imlib2
    ungoogled-chromium
    unzip
    xorg.libX11
    xorg.libXfixes
    xorg.libXft
    xorg.libXi
    xorg.libXinerama
    xorg.libxcb
    xscreensaver
    yajl
    zip
  ];

}
