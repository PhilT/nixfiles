{ config, pkgs, ... }:

{
  imports =
    [
      ./darko-minimal.nix
      ./common.nix
      ./nvidia.nix
      ./nvidia_offload.nix
    ];

  services = {
    auto-cpufreq.enable = true;  # TODO: Doc needed

    syncthing.key = "${../secrets/darko/syncthing.key.pem}";
    syncthing.cert = "${../secrets/darko/syncthing.cert.pem}";
  };

  programs.light.enable = true; # Key bindings in Dwm

  environment.systemPackages = with pkgs; [
  ];
}

