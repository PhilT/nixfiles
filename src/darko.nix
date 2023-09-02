{ config, pkgs, ... }:

let
  bin = "/run/current-system/sw/bin";
in
{
  imports =
    [
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
        { keys = [ 224 ]; events = [ "key" ]; command = "${bin}/light -U 5"; }
        { keys = [ 225 ]; events = [ "key" ]; command = "${bin}/light -A 5"; }
        { keys = [ 113 ]; events = [ "key" ]; command = "${bin}/pactl set-sink-volume 0 0"; }
        { keys = [ 114 ]; events = [ "key" ]; command = "${bin}/pactl set-sink-volume 0 -5%"; }
        { keys = [ 115 ]; events = [ "key" ]; command = "${bin}/pactl set-sink-volume 0 +5%"; }
      ];
    };

    syncthing.key = "../darko/syncthing.key.pem";
    syncthing.cert = "../darko/syncthing.cert.pem";
  };

  programs.light.enable = true;

  environment.systemPackages = with pkgs; [
  ];
}

