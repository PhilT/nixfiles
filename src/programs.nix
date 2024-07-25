{ config, pkgs, ... }:

{
  programs = {
    # `j term` cd quickly
    autojump.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    dconf.enable = true;

    # Starship - Highly configurable shell prompt
    starship.enable = true;

    # Log all history to a separate history file after every command.
    # CTRL+R stays clean for the current shell but you can always refer
    # to ~/.persistent_history if you need a command from another shell.
    # Use hgrep (below) to search this history file.
    bash.promptInit = ''
      log_bash_persistent_history() {
        [[ $(history 1) =~ ^\ *[0-9]+\ +(.*)$ ]]
        local cmd="''${BASH_REMATCH[1]}"
        if [[ "$cmd" != "$PERSISTENT_HISTORY_LAST" && "$cmd" != "hcat" && "$cmd" != "hcompact" ]]; then
          echo "$cmd" >> ~/.persistent_history
          export PERSISTENT_HISTORY_LAST="$cmd"
        fi
      }
    '';

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
      fd = "fd -H";
    };
  };

  environment = {
    sessionVariables = {
      PROMPT_COMMAND = "log_bash_persistent_history";
      HISTIGNORE = "history";
    };
    systemPackages = with pkgs; [
      (callPackage ./studio.nix {})
      (callPackage ./spectrum.nix {})

      # yt-dlp -x --audio-format mp3 https://URL
      yt-dlp

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

      # Search in ~/.persistent_history file (see above)
      (writeShellScriptBin "hgrep" "grep $@ ${config.userHome}/.persistent_history")
      (writeShellScriptBin "hcat" "cat ${config.userHome}/.persistent_history")
      (writeShellScriptBin "hcompact" "awk -i inplace '!seen[$0]++' ${config.userHome}/.persistent_history") # Runs on Hyprland start

      # Search and add Wifi
      (writeShellScriptBin "wifis" "iwctl station wlan0 get-networks")
      (writeShellScriptBin "wific" ''
        if [[ "$1" == "" ]]; then
          echo "Usage: wific <Network name> <passphrase>"
          exit 0
        fi

        iwctl --passphrase $2 station wlan0 connect $1
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

      # System and hardware information: lsusb, lspci, lscpu, lsblk
      usbutils
      pciutils
      cpu-x
      lshw

      # Utils
      exfatprogs            # Tools for managing exfat partitions on USB sticks (Use instead of fat32 as
      gparted               # it has large file support).
      nix-prefetch-github   # <owner> <repo> - Get SHA and REV of Github repo for e.g. youtube-dl (above)
      nvd                   # Nix diff versions (Used in ./build)
      inotify-tools

      # Audio/visual tools
      hyprshot              # Screnshot tool
      gimp
      goxel                 # Voxel editor
      feh                   # Image viewer
      yad                   # GUI Dialog for Goxel
      inkscape
      mpv                   # Video player
      simplescreenrecorder

      # Comms
      discord
      element-desktop       # Matrix chat client
      libreoffice
      slack
      whatsapp-for-linux

      fd                    # Alternative to find
      keepassxc
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