{ config, pkgs, ... }:

{
  imports = [
    ./minimal.nix
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
          rev = "225b4fa052ecd2eac5ad9fe8978bfeb73ac53038";   # Could move this to machine specific config to have diff configs
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
    "tmux/tmux.conf" = { source = ./dotfiles/tmux.conf; };
    "gitconfig" = { source = ./dotfiles/gitconfig; };
    "gitignore" = { source = ./dotfiles/gitignore; };
    "ignore" = { source = ./dotfiles/ignore; };
  };

  environment.extraInit = ''
    ln -fs /etc/config/alacritty.yml $XDG_CONFIG_HOME/alacritty.yml
  '';

  # Programs
  #-----------
  programs.slock.enable = true;              # xautolock also added in services

  # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
  programs.direnv.enable = true;

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
        source ${./neovim/colors/greyscale.vim}

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

        luafile ${./neovim/functions.lua}
        luafile ${./neovim/vars.lua}
        luafile ${./neovim/opts.lua}
        luafile ${./neovim/theme.lua}
        luafile ${./neovim/keys.lua}
        luafile ${./neovim/autocmds.lua}
        luafile ${./neovim/plugins/lualine.lua}
        luafile ${./neovim/plugins/fugitive.lua}
        luafile ${./neovim/plugins/nvimtree.lua}
        luafile ${./neovim/plugins/purescript.lua}
        luafile ${./neovim/plugins/ripgrep.lua}
        luafile ${./neovim/plugins/ruby.lua}
        luafile ${./neovim/plugins/scratch.lua}
        luafile ${./neovim/plugins/telescope.lua}
        luafile ${./neovim/plugins/fsharp.lua}
      '';
    };
  };

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
