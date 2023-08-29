{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./minimal.nix
    ./neovim.nix
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

    syncthing = {
      enable = true;
      user = "phil";
      dataDir = "/home/phil";
      overrideDevices = true; # Removes devices from Syncthing that are not configured here
      overrideFolders = true; # Removes folders from Syncthing that are not configured here
      settings = {
        options = {
          localAnnouceEnabled = false;
          urAccepted = -1;
        };
        gui.theme = "black";
        devices = {
          "spruce" = { id = "Y5VVR77-QCSCSU3-QWOXSVW-V4E75O4-BJ4DFC7-VWYVEMI-CSOAB24-6HYWCAK"; };
          "darko" = { id = "IJ6Z7AG-JESH6MF-DNUNQ7H-5C7ZESQ-DC6QK33-VCTNOQR-7S2KYGH-XTQBFAV"; };
          "mev" = { id = "IJ6Z7AG-JESH6MF-DNUNQ7H-5C7ZESQ-DC6QK33-VCTNOQR-7S2KYGH-XTQBFAV"; }
        };
        folders = {
          "Sync" = {                                # Name (and ID) of folder in Syncthing
            path = "/data/sync";                    # Which folder to add to Syncthing
            devices = [ "spruce" "darko" "mev" ];   # Which devices to share the folder with
            copyOwnershipFromParent = true;
          };
          "Music" = {
            path = "/data/music";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
          "Camera" = {
            path = "/data/pictures/camera";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
          "Txt" = {
            path = "/data/txt";
            devices = [ "spruce" "darko" "mev" ];
            copyOwnershipFromParent = true;
          };
        };
      };
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

  environment = {
    sessionVariables = rec {
      CDPATH   = "${CODE_DIR}";
      CODE_DIR = "$HOME/code";
      TXT_DIR  = "$HOME/txt";
      DOTNET_CLI_TELEMETRY_OPTOUT = "true";
      FZF_DEFAULT_COMMAND = "rg --files --no-ignore-vcs --hidden --ignore-file ~/.ignore";
      HISTCONTROL = "ignorespace:erasedups";   # Don't add commands starting with space, remove previous occurrances of command
      HISTFILESIZE = "";                       # Unlimited history
      HISTSIZE = "";                           # Unlimited history
      XDG_CONFIG_HOME = "$HOME/.config";
    };

    interactiveShellInit = ''
      alias ss='feh -Z -F -D 15'

      if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
        startx
      fi
    '';

    etc = {
      "config/alacritty.yml" = {
        text = ''
          font:
            size: 8
          '';

        mode = "444";
      };

      "xdg/nvim/colors/greyscale.vim" = { source = ./neovim/colors/greyscale.vim; };
      "gitignore" = { source = ./dotfiles/gitignore; };
      "ignore" = { source = ./dotfiles/ignore; };
    };

    extraInit = ''
      ln -fs /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
    '';

    systemPackages = with pkgs; [
      alacritty
      dmenu
      feh
      fsautocomplete
      pcmanfm
      ripgrep
      ungoogled-chromium
      unzip
      zip
    ];
  };

  # xautolock also added in services
  programs.slock.enable = true;

  # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
  programs.direnv.enable = true;
}
