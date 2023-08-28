{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./common.nix
    ];

  networking.hostName = "darko";

  services.auto-cpufreq.enable = true;
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    # nix-shell -p input-utils --run "sudo lsinput"
    # nix-shell -p actkbd --run "sudo actkbd -n -s -d /dev/input/event1"
    bindings = [
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 1"; }
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 1"; }
    ];
  };


  environment.systemPackages = with pkgs; [
  ];

}

