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

  programs.kitty.fontSize = 11;

  services = {
    auto-cpufreq.enable = true;  # TODO: Doc needed

    syncthing.key = "${../../secrets/darko/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/darko/syncthing.cert.pem}";
  };

  programs.light.enable = true; # Key bindings in Dwm

  services.libinput.enable = true;  # Touchpad support
  services.libinput.touchpad.naturalScrolling = true;
  services.libinput.touchpad.disableWhileTyping = true;
}