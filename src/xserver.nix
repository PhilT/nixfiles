{ config, pkgs, ... }:

{
  services = {
    picom.enable = true; # Compositor
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
        src = /data/code/dusk;
        prePatch = previousAttrs.prePatch + ''
          sed -i "s@/usr/share/xsessions@$out/share/applications/@g" Makefile
        '';
        buildInputs = previousAttrs.buildInputs ++ [
          pkgs.imlib2
          pkgs.yajl
          pkgs.xorg.libXi
          pkgs.xorg.libXfixes
        ];
#        src = builtins.fetchGit {
#          url = "https://github.com/bakkeby/dusk.git";
#          ref = "master";
#        };
#        src = builtins.fetchGit {
#          url = "https://github.com/PhilT/dusk.git";
#          ref = "master";
#        };
      });
    };
  };
}
