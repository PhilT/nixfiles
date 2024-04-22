{ config, pkgs, ... }:

let
  graytheme = pkgs.vimUtils.buildVimPlugin {
    name = "komau.vim";
    src = pkgs.fetchFromGitHub {
      owner = "ntk148v";
      repo = "komau.vim";
      rev = "master";
      sha256 = "p9Yo8nAJeY8jtyyqaGh0qYRD8w+S2N5SiH27DS5gSN4=";
    };
  };
  colorscheme = pkgs.vimUtils.buildVimPlugin {
    name = "vim-colors-pencil";
    src = pkgs.fetchFromGitHub {
      owner = "preservim";
      repo = "vim-colors-pencil";
      rev = "master";
      sha256 = "l/v5wXs8ZC63OmnI1FcvEAvWJWkaRoLa9dlL1NdX5XY=";
    };
  };
  fsharp = pkgs.vimUtils.buildVimPlugin {
    name = "vim-fsharp";
    src = pkgs.fetchFromGitHub {
      owner = "PhilT";
      repo = "vim-fsharp";
      rev = "master";
      sha256 = "IJQp6GeJkotjJkHbosJay7mUwaa6QhE8bLx6+TerVHU=";
    };
  };
  scratch = pkgs.vimUtils.buildVimPlugin {
    name = "scratch,vim";
    src = pkgs.fetchFromGitHub {
      owner = "mtth";
      repo = "scratch.vim";
      rev = "master";
      sha256 = "P8SuMZKckMu+9AUI89X8+ymJvJhlsbT7UR7XjnWwwz8=";
    };
  };
  winresizer = pkgs.vimUtils.buildVimPlugin {
    name = "winresizer";
    src = pkgs.fetchFromGitHub {
      owner = "simeji";
      repo = "winresizer";
      rev = "master";
      sha256 = "5LR9A23BvpCBY9QVSF9PadRuDSBjv+knHSmdQn/3mH0=";
    };
  };
  slim = pkgs.vimUtils.buildVimPlugin {
    name = "vim-slim";
    src = pkgs.fetchFromGitHub {
      owner = "slim-template";
      repo = "vim-slim";
      rev = "master";
      sha256 = "dkFTxBi0JAPuIkJcVdzE8zUswHP0rVZqiCE6NMywDm8=";
    };
  };
  neovimNoThemes = pkgs.neovim-unwrapped.overrideAttrs ({
    postUnpack = ''
      rm source/runtime/colors/*
    '';
  });
in
{
  environment = {
    # Language servers
    systemPackages = with pkgs; [
      dotnet-sdk_8
      csharp-ls
      fsautocomplete
      clang-tools

      # Ruby and Solargraph LSP specified in ruby.nix
    ];
  };

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
          completion-nvim
          fsharp
          himalaya-vim
          lualine-nvim
          nvim-lspconfig             # Language server client settings
          nvim-tree-lua
          plenary-nvim               # Required by Telescope
          quickfix-reflector-vim
          scratch
          slim
          telescope-fzy-native-nvim
          telescope-nvim
          todo-txt-vim
          vader-vim
          vim-abolish
          vim-css-color
          vim-dispatch
          vim-fugitive
          vim-glsl
          vim-indentwise
          vim-markdown
          vim-nix
          vim-repeat
          vim-scriptease
          vim-surround
          vim-tmux-navigator
          winresizer
        ];

      };
      customRC = ''
        source ${../neovim/colors/greyscale.vim}
        source ${../neovim/plugins/himalaya.vim}

        lua << LUADOC
          vim.g.loaded_netrw = 1  -- Disable netrw due to race conditions with nvim-tree
          vim.g.loaded_netrwPlugin = 1

          -- SPACE+; to get original cmdline mode, incase anything goes wrong with plugins
          vim.keymap.set('n', '<Leader>;', ':', { noremap = true })

          function ReloadConfig()
            for name,_ in pairs(package.loaded) do
              package.loaded[name] = nil
            end

            dofile(vim.env.MYVIMRC)
            vim.notify("Nvim configuration reloaded!", vim.log.levels.INFO)
          end
        LUADOC

        luafile ${../neovim/functions.lua}
        luafile ${../neovim/vars.lua}
        luafile ${../neovim/opts.lua}
        luafile ${../neovim/theme.lua}
        luafile ${../neovim/keys.lua}
        luafile ${../neovim/autocmds.lua}
        luafile ${../neovim/plugins/lualine.lua}
        luafile ${../neovim/plugins/fugitive.lua}
        luafile ${../neovim/plugins/nvimtree.lua}
        luafile ${../neovim/plugins/purescript.lua}
        luafile ${../neovim/plugins/ripgrep.lua}
        luafile ${../neovim/plugins/ruby.lua}
        luafile ${../neovim/plugins/scratch.lua}
        luafile ${../neovim/plugins/telescope.lua}
        luafile ${../neovim/plugins/fsharp.lua}
        luafile ${../neovim/plugins/lsp.lua}
      '';
    };
  };
}