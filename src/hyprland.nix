{ config, pkgs, ... }:

{
  # [ ] Shortcuts for `systemctl suspend`, `reboot`, `shutdown now` (configure power button)
  # [ ] Cursors
  # [ ] Themes
  # [ ] Make SDDM look nicer
  # [ ] Better way to setup bluetooth devices
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Thunderbird config
  # [ ] Impermanence?
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

  programs.hyprland.enable = true;

  programs.waybar.enable = true;

  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "phil";

    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/hypr - phil users -"
    "L+ ${config.xorg.xdgConfigHome}/hypr/hyprland.conf - - - - /etc/xdg/hypr/hyprland.conf"
  ];

  environment = {
    etc = {
      "xdg/hypr/hyprland.conf".source = ../dotfiles/hyprland.conf;
      "xdg/waybar/config.jsonc".source = ../dotfiles/waybar.jsonc;
    };

    # Optional, hint electron apps to use wayland:
    sessionVariables.NIXOS_OZONE_WL = "1";

    systemPackages = with pkgs; [
      wofi
#    networkmanagerapplet
      hyprpaper
    ];
  };
}