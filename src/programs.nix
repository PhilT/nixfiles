# TODO: Consider merging with common.nix mirroring common_gui.nix
{ config, pkgs, ... }: {
  programs = {
    # `j term` cd quickly
    autojump.enable = true;

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
      starship_precmd_user_func=log_bash_persistent_history
    '';

    bash.shellAliases = {
      ss = "imv -t 15 -f";
      fd = "fd -H";
      list-packages = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq";
    };
  };

  environment = {
    sessionVariables = {
      HISTIGNORE = "history";
    };
    systemPackages = with pkgs; [
      # yt-dlp -x --audio-format mp3 https://URL
      yt-dlp

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
      (writeShellScriptBin "hcompact" "awk -i inplace '!seen[$0]++' ${config.userHome}/.persistent_history") # Runs on Sway start

      # System and hardware information: lsusb, lspci, lscpu, lsblk
      usbutils
      pciutils
      cpu-x
      lshw

      # Utils
      exfatprogs            # Tools for managing exfat partitions on USB sticks (Use instead of fat32 as it has large file support).
      nix-prefetch-github   # <owner> <repo> - Get SHA and REV of Github repo for e.g. youtube-dl (above)
      nvd                   # Nix diff versions (Used in ./build)
      nix-tree              # Tree view of Nix derivations
      inotify-tools
      ncdu                  # Tree-based, interactive du

      fd                    # Alternative to find
      ripgrep
      unzip
      zip
    ];
  };
}