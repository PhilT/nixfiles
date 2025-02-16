{ config, pkgs, ... }:

{
  security.rtkit.enable = true; # Realtime priority for PulseAudio

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    pavucontrol           # Audio control panel
    pulseaudio
  ];
}