{ config, pkgs, ... }:

{
  imports = [
    ./environment.nix
    ./git.nix
    ./minimal.nix
    ./neovim.nix
    ./syncthing.nix
    ./tmux.nix
  ];

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  security.rtkit.enable = true; # Realtime priority for PulseAudio

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
      libinput.enable = true;                # Touchpad support
      xautolock.enable = true;

      layout = "gb";
      displayManager = {
        lightdm.enable = false;
        startx.enable = true;
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

  programs = {
    # xautolock also added in services
    programs.slock.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
    };
  };

}
