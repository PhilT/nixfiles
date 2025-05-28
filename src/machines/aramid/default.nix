# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }: {
  imports = [
    <nixos-hardware/lenovo/thinkpad/x1/12th-gen>
    <catppuccin/modules/nixos>

    ./minimal.nix
    ../../hardware/bluetooth.nix
    ../../ephemeral_os.nix
    ../../plymouth.nix
    ../../common.nix
    ../../common_gui.nix
    ../../development.nix

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
    "clock"
    "tray"
  ];

  environment.systemPackages = with pkgs; [
    pamixer           # Control volume with laptop media keys
    playerctl         # Control playback with laptop media keys
  ];

  # CPU power/speed optimiser https://github.com/AdnanHodzic/auto-cpufreq
  services.auto-cpufreq.enable = true;

  hardware.graphics.enable = true;
  networking.networkmanager.wifi.powersave = true;
}