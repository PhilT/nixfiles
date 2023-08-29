{ config, pkgs, ... }:

{
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

    loginShellInit = ''
      [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]] && startx    # Start X unless already started
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
      [ -f $HOME/.bash.private ] && source $HOME/.bash.private
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
}
