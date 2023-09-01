{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
      ./nvidia.nix
      ./nvidia_offload.nix
    ];

  networking.hostName = "darko";

  services = {
    auto-cpufreq.enable = true;
    actkbd = {
      enable = true;
      # nix-shell -p input-utils --run "sudo lsinput"
      # nix-shell -p actkbd --run "sudo actkbd -n -s -d /dev/input/event1"
      bindings = [
        { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 5"; }
        { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 5"; }
      ];
    };

    syncthing.key = "./darko/syncthing.key.pem";
    syncthing.cert = "./darko/syncthing.cert.pem";
  };

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
  ];
}

