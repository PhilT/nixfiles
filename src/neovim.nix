{ config, pkgs, ... }:

let
  graytheme = pkgs.vimUtils.buildVimPlugin {
    pname = "komau.vim";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "ntk148v";
      repo = "komau.vim";
      rev = "master";
      sha256 = "gGMlh+MqjgrJClsqZc7gylbMaXlQKmCqkEjJw8iGf/Q=";
    };
  };
  colorscheme = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-colors-pencil";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "preservim";
      repo = "vim-colors-pencil";
      rev = "master";
      sha256 = "l/v5wXs8ZC63OmnI1FcvEAvWJWkaRoLa9dlL1NdX5XY=";
    };
  };
  fsharp = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-fsharp";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "PhilT";
      repo = "vim-fsharp";
      rev = "master";
      sha256 = "IJQp6GeJkotjJkHbosJay7mUwaa6QhE8bLx6+TerVHU=";
    };
  };
  winresizer = pkgs.vimUtils.buildVimPlugin {
    pname = "winresizer";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "simeji";
      repo = "winresizer";
      rev = "299076f7f79e2e2f7706b2dfacbb3c074ce53257";
      sha256 = "sha256-rTTe6hFgEz9CFPJFDUjoD3SQr97V5E5Lg6J4c8mU+6s=";
    };
  };
  slim = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-slim";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "slim-template";
      repo = "vim-slim";
      rev = "master";
      sha256 = "mPv0tiggGExEZNshDlHtT4ipv/5Q0ahkcVw4irJ8l3o=";
    };
  };
  neovimNoThemes = pkgs.neovim-unwrapped.overrideAttrs {
    postUnpack = ''
      rm source/runtime/colors/*
    '';
  };
in
{
  programs.neovim = {
    package = neovimNoThemes;
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          colorscheme
          graytheme
          nord-nvim
          awesome-vim-colorschemes

          auto-pairs
          catppuccin-nvim
          claudecode-nvim
          fsharp
          leap-nvim
          lualine-nvim
          nvim-dap                  # Debugging adapter
          nvim-dap-ui               # UI for nvim-dap
          nvim-lspconfig            # Language server client settings
          nvim-tree-lua
          nvim-treesitter
          nvim-treesitter.withAllGrammars  # Include all tree-sitter parsers
          quickfix-reflector-vim
          render-markdown-nvim
          rustaceanvim              # Forked: rust-tools.nvim, for debugger
          slim
          supermaven-nvim
          fzf-lua
          todo-txt-vim
          toggleterm-nvim
          vader-vim
          vim-abolish
          vim-css-color
          vim-dispatch
          vim-fugitive
          vim-glsl
          vim-indentwise
          vim-nix
          vim-repeat
          vim-scriptease
          vim-surround
          vim-tmux-navigator
          winresizer
        ];

      };
      customRC = ''
        lua dofile('/data/code/nixfiles/neovim/init.lua')
      '';
    };
  };
}