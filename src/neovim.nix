{ config, pkgs, ... }:

let
  graytheme = pkgs.vimUtils.buildVimPlugin {
    pname = "komau.vim";
    version = "0.0.1";
    src = pkgs.fetchFromGitHub {
      owner = "ntk148v";
      repo = "komau.vim";
      rev = "master";
      sha256 = "p9Yo8nAJeY8jtyyqaGh0qYRD8w+S2N5SiH27DS5gSN4=";
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
      rev = "master";
      sha256 = "5LR9A23BvpCBY9QVSF9PadRuDSBjv+knHSmdQn/3mH0=";
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
  environment = {
    # Language servers
    systemPackages = with pkgs; [
      clang-tools
      csharp-ls
      dotnet-sdk_8
      fsautocomplete
      terraform-ls
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
          catppuccin-nvim
          fsharp
          lualine-nvim
          nvim-lspconfig             # Language server client settings
          nvim-tree-lua
          nvim-treesitter
          plenary-nvim               # Required by Telescope
          quickfix-reflector-vim
          slim
          supermaven-nvim
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
        " source ${../neovim/colors/greyscale.vim}

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
        luafile ${../neovim/plugins/ai.lua}
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