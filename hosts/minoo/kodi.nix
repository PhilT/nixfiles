{ config, pkgs, ... }:
{
  services.kodi = {
    enable = true;
    openFirewall = true;
    package = pkgs.kodi-gbm.withPackages (p: [
      # video
      p.a4ksubtitles
      p.formula1
      p.inputstream-ffmpegdirect
      p.inputstream-adaptive
      p.netflix
      p.pvr-iptvsimple
      p.raiplay
      p.upnext
      p.youtube

      # audio
      p.radioparadise

      # gaming
      p.iagl
      p.infotagger # missing dep for iagl
      p.joystick
      p.libretro-genplus
      p.libretro-mgba
      p.libretro-snes9x
      p.libretro-fuse
      p.libretro-nestopia
      p.controller-topology-project
    ]);

    settings = {
      # addons managed by nix
      general = {
        addonupdates = 2;
        addonnotifications = false;
      };
      # autoplay next episodes
      videoplayer.autoplaynextitem = "1,2";
      # videoscreen.resolution = "17";
    };

    addonSettings = {
      # here you need to add the entire configuration
      "plugin.video.youtube" = {
        # ...
      };
      "plugin.video.netflix" = {
        # ...
      };
    };
  };

  services.upower.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "kodi" && (
        action.id.indexOf("org.freedesktop.upower.") == 0 ||
        action.id.indexOf("org.freedesktop.login1.") == 0 ||
        action.id.indexOf("org.freedesktop.udisks.") == 0
      )) {
        return polkit.Result.YES;
      }
    });
  '';
}
