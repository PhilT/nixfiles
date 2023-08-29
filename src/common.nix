{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./minimal.nix
    ./neovim.nix
    ./tmux.nix
  ];

  # Nix settings
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  # Enable the X11 windowing system
  services = {
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

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };
  services.gvfs.enable = true;               # Automount USB drives

  # Environment variables
  environment.sessionVariables = rec {
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

  environment.interactiveShellInit = ''
    alias ss='feh -Z -F -D 15'

    if [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]]; then
      startx
    fi
  '';

  environment.etc = {
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

  environment.extraInit = ''
    ln -fs /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';

  # Programs
  #-----------

  # xautolock also added in services
  programs.slock.enable = true;

  # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
  programs.direnv.enable = true;

  environment.systemPackages = with pkgs; [
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

}
