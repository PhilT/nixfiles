# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>

    ./minimal.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/ephemeral_os.nix
    ../../modules/plymouth.nix
    ../../modules/common.nix
    ../../modules/common_gui.nix
    ../../modules/development.nix
    ../../modules/steam.nix
    ../../modules/studio.nix

    # Sync
    ../../modules/ssh.nix
    ../../modules/unison/minoo.nix

    # Windowing
    ../../modules/sway/mako.nix
    ../../modules/sway/tofi.nix
    ../../modules/sway/waybar.nix
    ../../modules/sway/default.nix

    # Laptops
    ../../modules/laptop/light.nix
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

  environment.shellAliases = {
    sprucet = "ssh spruce -t 'tmux new -A -s main'";
  };

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