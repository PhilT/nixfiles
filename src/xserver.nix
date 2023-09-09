{ config, pkgs, ... }:

{
  imports = [
    ./dwm/slstatus.nix
  ];

  # FIXME: (or remove) Not sure what this is doing. Look up.
  xdg.portal = {
    enable = true;
    # wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  services = {
    # Compositor
    picom = {
      enable = true;
      fade = true;
      fadeDelta = 12;
      inactiveOpacity = 0.9;
      activeOpacity = 1.0;
      settings = {
        inactive-dim = 0.4;
      };
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

  environment = {
    etc = {
      "xdg/wallpaper.jpg".source = ../media/wallpaper.jpg;
    };

    systemPackages = [
      (pkgs.writeShellScriptBin "autostart.sh" ''
        feh --no-fehbg --bg-scale /etc/xdg/wallpaper.jpg
        slstatus &
      '')
    ];
  };

  system.userActivationScripts.dwm-autostart = ''
    ln -fs /run/current-system/sw/bin/autostart.sh $HOME/.local/share/dwm/autostart.sh
  '';
}
