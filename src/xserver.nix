{ config, pkgs, ... }:

{
  imports = [
    ./dwm/slstatus.nix
  ];

  services = {
    # Compositor
    picom = {
      enable = true;
      vSync = true;
      fade = true;
      fadeDelta = 10;
      opacityRules = [
        "100:class_g = 'feh'"
      ];
      inactiveOpacity = 0.9;
      activeOpacity = 1.0;
      settings = {
        inactive-dim = 0.5;
        focus-exclude = "class_g = 'feh'";
      };
    };

    xserver = {
      enable = true;
      libinput.enable = true;  # Touchpad support - TODO: Move to darko?
      xautolock.enable = true; # Lock the screen

      layout = "gb";
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "phil";
      };
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs (finalAttrs: previousAttrs: {
        # TODO: Switch dwm source to git so we don't rely on local folder
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

    # TODO: Might make sense to separate this out into a autostart.nix for dwm
    # where options can be passed in to configure it.
    systemPackages = [
      (pkgs.writeShellScriptBin "autostart.sh" ''
        if [ "$(hostname)" = "spruce" ]; then
          feh --no-fehbg --bg-fill $DATA/downloads/wallpaper-right.jpg --bg-fill $DATA/downloads/wallpaper-left.jpg &
        else
          feh --no-fehbg --bg-fill /etc/xdg/wallpaper.jpg
        fi
        get_vol_perc > .volumestatus
        slstatus &
      '')
    ];
  };

  system.userActivationScripts.dwm-autostart = ''
    [ -d $HOME/.local/share/dwm ] || mkdir -p $HOME/.local/share/dwm
    ln -fs /run/current-system/sw/bin/autostart.sh $HOME/.local/share/dwm/autostart.sh
  '';
}
