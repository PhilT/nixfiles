{ config, pkgs, ... }:

let
  fsharp = pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "vim-fsharp";
    src = pkgs.fetchFromGitHub {
      owner = "PhilT";
      repo = "vim-fsharp";
      rev = "68bb8429a40f921f2ef62fd044a64170dc5458a1";
      sha256 = "IJQp6GeJkotjJkHbosJay7mUwaa6QhE8bLx6+TerVHU=";
    };
  };
  scratch = pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "scratch,vim";
    src = pkgs.fetchFromGitHub {
      owner = "mtth";
      repo = "scratch.vim";
      rev = "adf826b1ac067cdb4168cb6066431cff3a2d37a3";
      sha256 = "P8SuMZKckMu+9AUI89X8+ymJvJhlsbT7UR7XjnWwwz8=";
    };
  };
  winresizer = pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "winresizer";
    src = pkgs.fetchFromGitHub {
      owner = "simeji";
      repo = "winresizer";
      rev = "9bd559a03ccec98a458e60c705547119eb5350f3";
      sha256 = "5LR9A23BvpCBY9QVSF9PadRuDSBjv+knHSmdQn/3mH0=";
    };
  };
  slim = pkgs.vimUtils.buildVimPluginFrom2Nix {
    name = "vim-slim";
    src = pkgs.fetchFromGitHub {
      owner = "slim-template";
      repo = "vim-slim";
      rev = "f0758ea1c585d53b9c239177a8b891d8bbbb6fbb";
      sha256 = "dkFTxBi0JAPuIkJcVdzE8zUswHP0rVZqiCE6NMywDm8=";
    };
  };
in
{
  programs.neovim = {
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          auto-pairs
          completion-nvim
          editorconfig-vim
          fsharp
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
          vim-indentwise
          vim-markdown
          vim-repeat
          vim-scriptease
          vim-surround
          vim-tmux-navigator
          winresizer
        ];

      };
      customRC = ''
        source ${../neovim/colors/greyscale.vim}

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
      '';
    };
  };
}
