{ config, pkgs, ... }:
let
  macchiato-gtk = pkgs.catppuccin-gtk.override ({
    accents = [ "lavender" ];
    variant = "macchiato";
  });
in
{
  # [ ] Fix cursor size in Waybar & Firefox
  # [ ] Add hgrep (history)
  # [ ] Better way to setup bluetooth devices
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Thunderbird config
  # [ ] Impermanence?
  # [x] Cursors
  # [x] Themes
  # [x] Programs don't run from Tofi needed `| sh` at the end of the command
  # [x] keepmenu not working
  # [x] Win ENTER not working
  # [x] Shortcuts for `systemctl suspend`, `reboot`, `shutdown now` (configure power button)
  # [x] Replace SDDM with greetd (instead of Make SDDM look nicer)
  # [x] Move .config/hypr/hyprland.conf to Nix
  # [x] Move .config/waybar/config.jsonc to Nix
  # [x] Keyboard mappings?
  # [x] Workspace indicators
  # [x] Media keys
  # [x] Window borders/spacing
  # [x] Keyboard layout
  # [x] Fix touchpad scroll direction
  # [x] Remap CAPS
  # [x] Menu (dmenu?)

  imports = [
    <catppuccin/modules/nixos>
    ./tofi.nix
  ];

  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  programs.hyprlock.enable = true; # Also installs hypridle

  catppuccin.enable = true;
  catppuccin.flavor = "macchiato";

  services.pipewire.enable = true; # Screen sharing
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland";
        user = "phil";
      };
    };
  };

  environment = {
    etc = {
      "xdg/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
      "xdg/hypr/hyprlock.conf".source = ../dotfiles/hyprlock.conf;
      "xdg/hypr/macchiato.conf".source = ../dotfiles/macchiato.conf;
      "xdg/waybar/config.jsonc".source = ../dotfiles/waybar.jsonc;
      "xdg/waybar/macchiato.css".source = ../dotfiles/macchiato.css;
      "xdg/waybar/style.css".source = ../dotfiles/style.css;
    };

    systemPackages = with pkgs; [
      brightnessctl # TODO: Probably only needed for laptops
      macchiato-gtk
      catppuccin-cursors.macchiatoLavender
      dunst
      hyprpaper
      libnotify     # Used by hypridle
#    networkmanagerapplet
    ];


    sessionVariables = {
      GTK_THEME = "catppuccin-macchiato-lavender-standard+default";
      XCURSOR_THEME = "catppuccin-macchiato-lavender-cursors";

      NIXOS_OZONE_WL = "1"; # hint electron apps to use wayland:
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WMNONREPARENTING = "1";
      QT_QPA_PLATFORM = "wayland";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };

  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "L+ ${config.xdgConfigHome}/hypr - - - - /etc/xdg/hypr"

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgDataHome}/icons/default - - - - ${pkgs.catppuccin-cursors.macchiatoLavender}/share/icons/catppuccin-macchiato-lavender-cursors"
  ];
}