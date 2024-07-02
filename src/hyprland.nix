{ config, pkgs, ... }:
let
  macchiato-gtk = pkgs.catppuccin-gtk.override ({
    accents = [ "lavender" ];
    variant = "macchiato";
  });
in
{
  # [ ] Add psgrep, hgrep (history),
  # [ ] keepmenu not working
  # [ ] Cursors
  # [ ] Themes
  # [ ] Better way to setup bluetooth devices
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Thunderbird config
  # [ ] Impermanence?
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
  ];

  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  programs.hyprlock.enable = true;

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
      "xdg/hypr/hypridle.conf".source = ../dotfiles/hypridle.conf;
      "xdg/hypr/hyprlock.conf".source = ../dotfiles/hyprlock.conf;
      "xdg/hypr/macchiato.conf".source = ../dotfiles/macchiato.conf;
      "xdg/waybar/config.jsonc".source = ../dotfiles/waybar.jsonc;
      "xdg/waybar/macchiato.css".source = ../dotfiles/macchiato.css;
      "xdg/waybar/style.css".source = ../dotfiles/style.css;
    };

    systemPackages = with pkgs; [
      macchiato-gtk
      catppuccin-cursors.macchiatoLavender
      dunst
      hyprpaper
      libnotify     # Used by hypridle
      dmenu-wayland
      tofi
      #wofi
#    networkmanagerapplet
    ];

    # Optional, hint electron apps to use wayland:
    sessionVariables.NIXOS_OZONE_WL = "1";

    sessionVariables.GTK_THEME = "catppuccin-macchiato-lavender-standard+default";
    sessionVariables.XCURSOR_THEME = "catppuccin-macchiato-lavender-cursors";
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "L+ ${config.xdgConfigHome}/hypr - - - - /etc/xdg/hypr"
  ];
}