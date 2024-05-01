{ config, pkgs, ... }:

{
  programs = {
    # `j term` cd quickly
    autojump.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    dconf.enable = true;
    # xautolock also added in services
    #slock.enable = true;

    # Starship - Highly configurable shell prompt
    starship.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (callPackage ./studio.nix {})
      (callPackage ./spectrum.nix {})

      # youtube-dl -x --audio-format mp3 https://URL
      (youtube-dl.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "ytdl-org";
          repo = "youtube-dl";
          rev = "820fae3b3a8587a6f57afbe803b4f91de7d4e086";
          sha256 = "ikDcEn2fGl+Zcrd8YHDXhG/i9gQ1KLDesPOFyQsYp1g=";
        };
        patches = [];

        postInstall = false;
      }))

      (writeShellScriptBin "matter" ''
        cd $CODE/matter
        nix-shell shell.nix --run "nvim -S Session.vim"
      '')

      (writeShellScriptBin "gox" ''
        cd $CODE/matter
        nix-shell shell.nix --run "gox -s 2"
      '')

      (writeShellScriptBin "v" ''
        nvim -S Session.vim
      '')

      # Start Neovim with todays date as filename
      (writeShellScriptBin "note" ''
        cd $NOTES/log && nvim $(date +%Y-%m-%d).md
      '')

      # Reset file/folder permissions
      (writeShellScriptBin "resetperms" ''
        find . -type d -print0 | xargs -0 chmod 755
        find . -type f -print0 | xargs -0 chmod 644
      '')

      # TODO: Probably don't need this anymore
      (writeShellScriptBin "slk" ''
        if [ "$(hostname)" == "darko" ]; then
          export __NV_PRIME_RENDER_OFFLOAD=1
          export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
          export __GLX_VENDOR_LIBRARY_NAME=nvidia
          export __VK_LAYER_NV_optimus=NVIDIA_only
        fi

        /run/current-system/sw/bin/slack
      '')

      #(bluemail.overrideAttrs (old: {
      #  src = pkgs.fetchurl {
      #    url = "https://download.bluemail.me/BlueMail/deb/BlueMail.deb";
      #    sha256 = "dnYOb3Q/9vSDssHGS2ywC/Q24Oq96/mvKF+eqd/4dVw=";
      #  };
      #}))

      # System information: lsusb, lspci, lscpu, lsblk
      usbutils
      pciutils
      cpu-x

      # Utils
      exfatprogs            # Tools for managing exfat partitions on USB sticks (Use instead of fat32 as
      gparted               # it has large file support).
      nix-prefetch-github   # <owner> <repo> - Get SHA and REV of Github repo for e.g. youtube-dl (above)
      inotify-tools

      # Audio/visual tools
      flameshot             # Screnshot tool
      gimp
      goxel                 # Voxel editor
      feh                   # Image viewer
      yad                   # GUI Dialog for Goxel
      inkscape
      mpv                   # Video player
      simplescreenrecorder

      # Comms
      discord
      element-desktop       # Matrix chat client Connect to: #pimalaya.himalaya
      libreoffice
      slack
      thunderbird
      whatsapp-for-linux

      fd                    # Alternative to find
      keepassxc
      pinentry              # TODO: What is this?
      pulseaudio
      ripgrep
      shared-mime-info      # Recognise different file types
      unzip
      wineWowPackages.full  # Needed for FL Studdio installer
      xclip                 # Used by Neovim among other things for copy/paste from/to system clipboard
      zip
    ];
  };
}