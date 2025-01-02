{ config, pkgs, lib, ... }:

with lib;

{
  environment = {
    systemPackages = with pkgs; [
      kitty
      kitty-themes

      # Run kitty-themes to preview a list of themes. For some reason
      # --config-file-name doesn't work (Possibly because it can't write to the
      # main kitty.conf file). So, kitty-themes THEME NAME
      # will dump the theme into dotfiles/kitty-theme.conf then
      # just ./build to update.
      #
      # Current theme: Blazer
      # Other liked themes:
      # * Catppuccin-Mocha
      # * Catppuccin-Macchiato
      # * Doom One
      # * Dark One Nuanced
      (writeShellScriptBin "kitty-themes" ''
        if [ -z "$1" ]; then
          kitty +kitten themes
        else
          kitty +kitten themes --dump-theme $1 > $SRC/dotfiles/kitty-theme.conf
        fi
      '')
    ];

    sessionVariables = {
      KITTY_CONFIG_DIRECTORY = "/etc/config";
    };

    etc = {
      "config/kitty-theme.conf".source = ../dotfiles/kitty-theme.conf;
      "config/kitty.conf" = {
        mode = "444";
        text = ''
          include /etc/config/kitty-theme.conf
          font_family monospace
          font_size ${toString config.programs.kitty.fontSize}
          text_composition_strategy legacy
          copy_on_select clipboard
          strip_trailing_spaces always
          background_opacity 1.0
          scrollback_pager /run/current-system/sw/bin/nvim -u NONE -c "set nonumber nolist showtabline=0 foldcolumn=0 laststatus=0 noshowmode noruler noshowcmd shortmess+=F" -c "autocmd TermOpen * normal G" -c "map q :qa!<CR>" -c "set clipboard+=unnamedplus" -c "silent write! /tmp/kitty_scrollback_buffer | te echo -n \"$(cat /tmp/kitty_scrollback_buffer)\" && sleep 1000 "
        '';
      };
    };
  };
}