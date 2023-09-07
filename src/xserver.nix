{ config, pkgs, ... }:

{
  imports = [
    ./dwm/slstatus.nix
  ];

  services = {
    # Compositor
    picom = {
      enable = true;
      fade = true;
      fadeDelta = 20;
      inactiveOpacity = 0.6;
      activeOpacity = 0.9;
    };

    xserver = {
      enable = true;
      libinput.enable = true;  # Touchpad support
      xautolock.enable = true; # Lock the screen

      layout = "gb";
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "phil";
      };
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs (finalAttrs: previousAttrs: {
        src = /data/code/dwm;
        prePatch = previousAttrs.prePatch + ''
          sed -i "s@/usr/share/xsessions@$out/share/applications/@g" Makefile
        '';
#        src = builtins.fetchGit {
#          url = "https://github.com/PhilT/dwm.git";
#          ref = "master";
#        };
      });
    };
  };
}
