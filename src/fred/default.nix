{ config, pkgs, ... }:

{
  imports =
    [
      ./minimal.nix
      ./power.nix
      ../claudi.nix
    ];

  services = {
    auto-cpufreq.enable = true;  # TODO: Doc needed

    syncthing.key = "${../../secrets/fred/syncthing.key.pem}";
    syncthing.cert = "${../../secrets/fred/syncthing.cert.pem}";
  };


# Probably enabled by default in XFCE
#  programs.light.enable = true; # Key bindings are in Dwm

  environment.systemPackages = with pkgs; [
  ];
}

