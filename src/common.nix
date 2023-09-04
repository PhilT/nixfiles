{ config, pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./browser.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./neovim.nix
    ./syncthing.nix
    ./tmux.nix
    ./programs.nix
  ];

  security.rtkit.enable = true; # Realtime priority for PulseAudio
  virtualisation.docker.enable = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  services = {
    gvfs.enable = true; # Automount USB drives

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
    };

    xserver = {
      enable = true;
      libinput.enable = true;  # Touchpad support
      xautolock.enable = true; # Lock the screen

      layout = "gb";
      displayManager = {
        autoLogin.enable = true;
        autoLogin.user = "phil";
      };
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = builtins.fetchGit {
          url = "https://github.com/PhilT/dwm.git";
          ref = "main";
        };
      };
    };
  };
}
