{ config, pkgs, ... }:

{
  environment = {
    sessionVariables = rec {
      DATA = "/data";
      CODE = "${DATA}/code";
      SRC = "${CODE}/nixos-files";
      TXT  = "${DATA}/txt";
      CDPATH   = "${CODE}";
      DOTNET_CLI_TELEMETRY_OPTOUT = "true";
      FZF_DEFAULT_COMMAND = "rg --files --no-ignore-vcs --hidden --ignore-file ~/.ignore";
      HISTCONTROL = "ignorespace:erasedups";   # Don't add commands starting with space, remove previous occurrances of command
      HISTFILESIZE = "";                       # Unlimited history
      HISTSIZE = "";                           # Unlimited history
      XDG_CONFIG_HOME = "$HOME/.config";
    };

    #loginShellInit = ''
    #  [[ -z "$DISPLAY" ]] && [[ $(tty) = /dev/tty1 ]] && startx    # Start X unless already started
    #'';

    etc = {
      "chrom" = {
        mode = "555";
        text = "chromium --force-dark-mode https://www.startpage.com/sp/search?query=\"$@\" &";
      };
      "config/alacritty.yml" = {
        mode = "444";
        text = ''
          font:
            size: 8
          '';

      };
      ".bashrc.local".source = ../common/bashrc.local;
      "xdg/nvim/colors/greyscale.vim".source = ./neovim/colors/greyscale.vim;
      "gitignore".source = ./dotfiles/gitignore;
      "ignore".source = ./dotfiles/ignore;
    };

    extraInit = ''
      mkdir -p $XDG_CONFIG_HOME
      ln -fs /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
    '';
  };
}
