{ config, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Optional, hint electron apps to use wayland:
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # [ ] Workspace indicators
  # [ ] Keyboard mappings?
  # [ ] Cursors
  # [ ] Themes
  # [ ] Make SDDM look nicer
  # [ ] Better way to setup bluetooth devices
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Thunderbird config
  # [ ] Move .config/hypr/hyprland.conf to Nix
  # [ ] Impermanence?
  # [x] Media keys
  # [x] Window borders/spacing
  # [x] Keyboard layout
  # [x] Fix touchpad scroll direction
  # [x] Remap CAPS
  # [x] Menu (dmenu?)


  environment.systemPackages = with pkgs; [
    wofi
#    networkmanagerapplet
    waybar
    hyprpaper
  ];
}