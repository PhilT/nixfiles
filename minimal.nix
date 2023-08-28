# This is minimal config to get a bootable NixOS system with a single user.
# It could be used if the other configs don't boot a machine correctly into NixOS.

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  system.nixos.label = "BOOT_LABEL";
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices = {
    root = {
      device = "LVM_PARTITION";
      preLVM = true;
    };
  };

  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Internationalisation
  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };
  services.xserver.layout = "gb";
  services.xserver.xkbOptions = "ctrl:swapcaps";

  # User account
  users.extraUsers.USER_NAME = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = "USER_FULLNAME";
    hashedPassword = "USER_PASSWORD";
    extraGroups = [ "wheel" "networkmanager" "video" ];
  };
  users.mutableUsers = false;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
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

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    htop
    wget
    which
  ];

  # Services
  services.automatic-timezoned.enable = true;

  # Security
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "23.05"; # Did you read the comment?
}

