{ config, lib, pkgs, ... }:
let
  colors = import ../macchiato.nix lib;
  accent = "lavender";
  variant = "macchiato";
  catppuccin-gtk-macchiato = pkgs.catppuccin-gtk.override ({
    accents = [ accent ];
    variant = variant;
  });
  catppuccin-papirus-macchiato = pkgs.catppuccin-papirus-folders.override ({
    flavor = variant;
    accent = accent;
  });
in with colors; {
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.sway.enable = true;
  programs.sway.xwayland.enable = false; # Let's see if any apps need xwayland
  programs.sway.wrapperFeatures.gtk = true; # TODO: What is this?

  catppuccin.enable = true;
  catppuccin.flavor = variant;

  services.gnome.gnome-keyring.enable = true;
  services.pipewire.enable = true; # Screen sharing
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "/run/current-system/sw/bin/start_sway";
        user = config.username;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    catppuccin-gtk-macchiato
    catppuccin-cursors.macchiatoLavender
    catppuccin-papirus-macchiato

    # Add the the end of bin/sway for logging: -d |& tee sway.log
    # Keep hold of the old log file after a crash: [ -f sway.log ] && mv sway.log sway.log.old
    (writeShellScriptBin "start_sway" ''
      ${pkgs.sway}/bin/sway
    '')
  ];

  programs.sway.extraPackages = with pkgs; [
    vulkan-validation-layers    # Needed for WLR_RENDERER
    slurp
    grim
    swaybg
    swayidle
    swaylock
    overskride                  # Bluetooth GUI
  ];

  environment.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    XCURSOR_SIZE = "32";
    NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland: Fixes Slack
    # WLR_NO_HARDWARE_CURSORS = "1"; # Try if cursors keep disapearing/not rendering the correct one

    WLR_RENDERER = "vulkan";
    # WLR_EGL_NO_MODIFIERS = "1"; # Try this
    # WLR_DRM_NO_ATOMIC = "1";    # And this

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

  environment.etc = {
    "sway/config" = {
      source = ../../dotfiles/sway/config; mode = "444";
    };

    "sway/config.d/catppuccin-macchiato" = {
      source = ../../dotfiles/sway/catppuccin-macchiato; mode = "444";
    };

    "gtk-3.0/settings.ini" = {
      mode = "444";
      text = ''
        [Settings]
        gtk-application-prefer-dark-theme = true
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgDataHome} - ${config.username} users -"
    "d ${config.xdgDataHome}/icons - ${config.username} users -"
    "d ${config.xdgConfigHome} - ${config.username} users -"
    "d ${config.xdgConfigHome}/gtk-3.0 - ${config.username} users -"

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgDataHome}/icons/default - - - - ${pkgs.catppuccin-cursors.macchiatoLavender}/share/icons/catppuccin-macchiato-lavender-cursors"
    "L+ ${config.xdgConfigHome}/gtk-3.0/settings.ini - - - - /etc/gtk-3.0/settings.ini"

    "L+ ${config.xdgDataHome}/icons/cat-macchiato-lavender - - - - /run/current-system/sw/share/icons/Papirus-Dark"
  ];
}