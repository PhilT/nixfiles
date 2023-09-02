{ config, pkgs, ... }:

{
  programs.neovim = {
    configure = {
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          nvim-lspconfig             # Language server client settings
          plenary-nvim               # Required by Telescope
          vim-tmux-navigator
          lualine-nvim
          vim-css-color
          nvim-tree-lua
          telescope-nvim
          telescope-fzy-native-nvim
          #scratch-vim
          auto-pairs
          vim-indentwise
          vim-surround
          vim-repeat
          vim-dispatch
          quickfix-reflector-vim
          todo-txt-vim
          #winresizer
          vim-fugitive
          vim-markdown
          editorconfig-vim
          vim-abolish
          completion-nvim
          vim-fsharp
          vader-vim
          vim-scriptease
          #vim-slim
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
