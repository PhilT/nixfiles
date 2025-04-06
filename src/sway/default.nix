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
    config.common.default = "wlr";
    wlr.enable = true;
    wlr.settings.screencast = {
      output_name = "HDMI-A-1";
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.sway.enable = true;
  programs.sway.xwayland.enable = true;
  programs.sway.wrapperFeatures.gtk = true; # wrapper to execute sway with required environment variables for GTK applications
  programs.dconf.enable = true;             # Used in sway config to set some themes

  catppuccin.enable = true;
  catppuccin.flavor = variant;

  services.gnome.gnome-keyring.enable = true;
  services.pipewire.enable = true; # Screen sharing
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.sway}/bin/sway";
        user = config.username;
      };
      default_session = initial_session;
    };
  };

  environment.systemPackages = with pkgs; [
    catppuccin-gtk-macchiato
    catppuccin-papirus-macchiato
    catppuccin-cursors.macchiatoLavender
  ];

  programs.sway.extraPackages = with pkgs; [
    vulkan-validation-layers    # Needed for WLR_RENDERER
    slurp                       # Region selection, used by grim and wf-recorder
    grim                        # Screenshots
    swaybg
    swayidle
    swaylock
    overskride                  # Bluetooth GUI
    darkman
  ];

  environment.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    XCURSOR_SIZE = "48";
    NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland: Fixes Slack

    WLR_RENDERER = lib.mkIf config.vulkan.enable "vulkan";
  };

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