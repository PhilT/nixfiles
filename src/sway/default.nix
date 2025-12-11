{ config, lib, pkgs, ... }:
let
  colors = import ../catppuccin.nix lib;
  accent = "lavender";
  variant = "mocha";
  catppuccin-gtk-mocha = pkgs.catppuccin-gtk.override ({
    accents = [ accent ];
    variant = variant;
  });
in with colors; {
  imports = [
    ./config.nix
  ];

  xdg.portal = {
    enable = true;
    config.common.default = "wlr";
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  programs.sway.enable = true;
  programs.sway.xwayland.enable = true;
  programs.sway.wrapperFeatures.gtk = true; # wrapper to execute sway with required environment variables for GTK applications
  programs.dconf.enable = true;             # Used in sway config to set some themes

  catppuccin.enable = true;
  catppuccin.flavor = variant;

  services.gnome.gnome-keyring.enable = true;
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.sway}/bin/sway ${config.swayOptions}";
        user = config.username;
      };
      default_session = initial_session;
    };
  };

  environment.systemPackages = with pkgs; [
    catppuccin-gtk-mocha
    catppuccin-papirus-folders
    catppuccin-cursors.mochaLavender
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
    dconf-editor                # Used to check what settings are available in dconf
    psmisc                      # Provides pstree for finding shell processes
  ];

  environment.sessionVariables = {
    GTK_THEME = "catppuccin-mocha-lavender-standard";

    QT_SCALE_FACTOR = "2"; # Fixes KeePassXC
    NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland: Fixes Slack

    WLR_RENDERER = lib.mkIf config.vulkan.enable "vulkan";
  };

  environment.etc = {
    "sway/config.d/catppuccin-mocha" = {
      source = ../../dotfiles/sway/catppuccin-mocha; mode = "444";
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

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgDataHome}/icons/default - - - - ${pkgs.catppuccin-cursors.mochaLavender}/share/icons/catppuccin-mocha-lavender-cursors"

    "L+ ${config.xdgDataHome}/icons/cat-mocha-lavender - - - - /run/current-system/sw/share/icons/Papirus-Dark"
  ];
}