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

  # [x] Keyboard layout
  # [x] Fix touchpad scroll direction
  # [ ] Menu (dmenu?)
  # [ ] Keyboard mappings?
  # [x] Remap CAPS
  # [ ] Firefox bookmarks, settings, etc
  # [ ] Window borders/spacing
  # [ ] Impermanence?



  environment.systemPackages = with pkgs; [
    dolphin  # File browser
    wofi
    networkmanagerapplet
    waybar
    hyprpaper
  ];
}