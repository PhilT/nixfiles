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

  programs = {
    # xautolock also added in services
    slock.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
    };

    chromium = {
      enable = true;
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
        "fgmjlmbojbkmdpofahffgcpkhkngfpef" # Startpage
        "cdkhedhmncjnpabolpjceohohlefegak" # Startpage privacy protection
      ];
      defaultSearchProviderEnabled = false;
      homepageLocation = "https://startpage.com";
    };
  };

  virtualisation.docker.enable = true;

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      alacritty
      dmenu
      feh
      fsautocomplete
      gimp
      inkscape
      keepassxc
      keepmenu
      neomutt
      pcmanfm
      ripgrep
      chromium
      unzip
      zip
    ];
  };
}
