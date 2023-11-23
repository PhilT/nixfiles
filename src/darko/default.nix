{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ./power.nix
      ../phil.nix
      ../nvidia.nix
      ../nvidia_offload.nix
    ];

  programs.alacritty.fontSize = 10;
  programs.kitty.fontSize = 11;

  services = {
    auto-cpufreq.enable = true;  # TODO: Doc needed

    syncthing.key = "${../../secrets/darko/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/darko/syncthing.cert.pem}";
  };

  programs.light.enable = true; # Key bindings in Dwm

  services.xserver.libinput.enable = true;  # Touchpad support
  services.xserver.libinput.touchpad.naturalScrolling = true;
  services.xserver.libinput.touchpad.disableWhileTyping = true;

  environment.systemPackages = with pkgs; [
    steam-run # Needed to run Godot .NET
  ];
}