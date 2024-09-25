{ config, lib, pkgs, ... }:
let
  colors = import ./macchiato.nix lib;
  catppuccin-gtk-macchiato = pkgs.catppuccin-gtk.override ({
    accents = [ "lavender" ];
    variant = "macchiato";
  });
in with colors; {
  imports = [
    <catppuccin/modules/nixos>
    ./waybar.nix
    ./mako.nix
    ./tofi.nix
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.sway.enable = true;
  programs.sway.xwayland.enable = true;
  programs.sway.wrapperFeatures.gtk = true; # TODO: What is this?

  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";

  services.gnome.gnome-keyring.enable = true;
  services.pipewire.enable = true; # Screen sharing
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "/run/current-system/sw/bin/start_sway";
        user = "phil";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    catppuccin-gtk-macchiato
    catppuccin-cursors.macchiatoLavender

    (writeShellScriptBin "start_sway" ''
      [ -f sway.log ] && mv sway.log sway.log.old
      ${pkgs.sway}/bin/sway |& tee sway.log
    '')
  ];

  programs.sway.extraPackages = with pkgs; [
    brightnessctl # TODO: Probably only needed for laptops
    slurp
    grim
    mako
    swaybg
    swayidle
    swaylock
    waybar
  ];

  environment.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    XCURSOR_SIZE = "32";
    NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland: Fixes Slack

    # Not sure if any of this is needed, possibly the electron stuff
    # but need to test. Maybe with Nouveau drivers it's not needed anymore.
    # XDG_CURRENT_DESKTOP = "sway";
    # XDG_SESSION_DESKTOP = "sway";

    # SDL_VIDEODRIVER = "wayland";
    # QT_QPA_PLATFORM = "wayland";
    # QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    # _JAVA_AWT_WM_NONREPARENTING = "1";
    # MOZ_ENABLE_WAYLAND = "1";

    #  ELECTRON_OZONE_PLATFORM_HINT,auto # FIXME: Possibly not needed for non-nvidia
  };

  # Hopefully I can just use the above sessionVariables instead
  programs.sway.extraSessionCommands = ''
  '';

  environment.etc."sway/config" = {
    mode = "444";
    source = ../dotfiles/sway/config;
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgDataHome} - phil users -"
    "d ${config.xdgDataHome}/icons - phil users -"

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgDataHome}/icons/default - - - - ${pkgs.catppuccin-cursors.macchiatoLavender}/share/icons/catppuccin-macchiato-lavender-cursors"
  ];
}