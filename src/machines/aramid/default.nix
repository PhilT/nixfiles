# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    <catppuccin/modules/nixos>
    ../../catppuccin_compat.nix

    ./minimal.nix
    ../../hardware/bluetooth.nix
    ../../ephemeral_os.nix
    ../../plymouth.nix
    ../../common.nix
    ../../common_gui.nix
    ../../development.nix
    ../../steam.nix
    ../../studio.nix

    # Sync
    ../../ssh.nix
    ../../unison/minoo.nix

    # Windowing
    ../../sway/mako.nix
    ../../sway/tofi.nix
    ../../sway/waybar.nix
    ../../sway/default.nix

    # Laptops
    ../../laptop/light.nix
  ];

  waybarModules = [
    "pulseaudio"
    "network"
    "cpu"
    "memory"
    "disk"
    "temperature"
    "backlight"
    "battery"
    "bluetooth"
    "sway/language"
    "clock"
    "tray"
  ];

  environment.systemPackages = with pkgs; [
    pamixer           # Control volume with laptop media keys
    playerctl         # Control playback with laptop media keys
  ];

  # Enable Camera - One day this might work.
  hardware.ipu6.enable = true;
  hardware.ipu6.platform = "ipu6epmtl";

  hardware.graphics.enable = true;
  networking.networkmanager.wifi.powersave = true;

  # Keyboard layout: Colemak, Qwerty
  # (Reverses the default so we get Colemak on the laptop keyboard)
  # Alt+Shift toggles between the two
  keyboardVariant = ",colemak_dh";
}