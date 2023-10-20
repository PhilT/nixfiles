{ config, pkgs, ... }:

{
  imports = [
    ./dwm/slstatus.nix
    ./dwm/adjustlight.nix
  ];

  services = {
    # Compositor
    picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      fade = true;
      fadeDelta = 10;
      settings = {
        inactive-dim = 0.4;
        inactive-dim-fixed = true;
        focus-exclude = [
          "class_g = 'feh'"
          "x = 0 && y = 0 && override_redirect = true"
          "x = 3840 && y = 0 && override_redirect = true"
        ];
      };
    };

    xserver = {
      enable = true;
      #xautolock.enable = true; # Lock the screen

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
        #src = builtins.fetchGit {
        #  url = "https://github.com/PhilT/dwm.git";
        #  ref = "main";
        #  rev = "932c70db7e59cd521ec9f6bebf5df2fd9623365c";
        #};
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
        /run/current-system/sw/bin/setxkbmap   # Fix character encoding issue when pasting text for keepmenu with xdotool or py
        if [ "$(hostname)" = "spruce" ]; then
          feh --no-fehbg --bg-fill $DATA/downloads/wallpaper-right.jpg --bg-fill $DATA/downloads/wallpaper-left.jpg &
        else
          feh --no-fehbg --bg-fill /etc/xdg/wallpaper.jpg
        fi
        get_vol_perc > .volumestatus
        xset s blank # Blank screen (disable screensaver)
        slstatus &
        flameshot &
      '')
    ];
  };

  system.userActivationScripts.dwm-autostart = ''
    [ -d $HOME/.local/share/dwm ] || mkdir -p $HOME/.local/share/dwm
    ln -fs /run/current-system/sw/bin/autostart.sh $HOME/.local/share/dwm/autostart.sh
  '';
}
