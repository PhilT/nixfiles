{ config, pkgs, lib, ... }:

let
  DATA = "/data";
  CODE = "${DATA}/code";
in
{
  options.xorg.xdgConfigHome = lib.mkOption {
    type = lib.types.str;
    default = "/home/phil/.config";
    description = "Standard XDG_CONFIG_HOME";
  };

  options.xorg.xdgDataHome = lib.mkOption {
    type = lib.types.str;
    default = "/home/phil/.local/share";
    description = "Standard $XDG_DATA_HOME";
  };

  config = {
    systemd.tmpfiles.rules = [
      "d /data - phil users"
      "d /data/downloads - phil users"
    ];

    environment = {
      sessionVariables = {
        # Duplicated in ./initialize
        DATA = DATA;
        CODE = CODE;
        SRC = "${CODE}/nixos-files";
        NOTES  = "${DATA}/notes";
        CDPATH   = "${CODE}:${DATA}";
        DOTNET_CLI_TELEMETRY_OPTOUT = "true";
        FZF_DEFAULT_COMMAND = "rg --files --no-ignore-vcs --hidden --ignore-file ~/.ignore";
        HISTCONTROL = "ignorespace:erasedups";   # Don't add commands starting with space, remove previous occurrances of command
        HISTFILESIZE = "";                       # Unlimited history
        HISTSIZE = "";                           # Unlimited history
        XDG_CONFIG_HOME = config.xorg.xdgConfigHome;
        GTK_THEME = "Adwaita:dark";  # TODO: Move to xserver config?
      };

      etc = {
        "bashrc.local".source = ../secrets/bashrc.local;
        "xdg/nvim/colors/greyscale.vim".source = ../neovim/colors/greyscale.vim;
        "gitignore".source = ../dotfiles/gitignore;
        "ignore".source = ../dotfiles/ignore;
      };
    };
  };
}