# TODO: Consider merging with common.nix mirroring common_gui.nix
# Or perhaps split things up into more specific files.
{ config, pkgs, ... }: {
  programs = {
    starship.enable = true; # Starship - Highly configurable shell prompt
    neovim.enable = true;
    neovim.withRuby = false;
    neovim.defaultEditor = true;
    git.enable = true;

    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs here
      # Use ldd <path to binary> to get a list
    ];
  };

  environment = {
    shellAliases = {
      l = "ls -alh";
      ss = "imv -t 15 -f";
      fd = "fd -H";
      ls-packages = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq";
      ls-references = "nix-store --query --roots "; # add /nix/store/<hash>-package-name from fd package-name /
      ls-generations = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
      rm-generations = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations";
      rm = "trash";
    };

    systemPackages = with pkgs; [
      # yt-dlp -x --audio-format mp3 https://URL
      yt-dlp

      (writeShellScriptBin "sw-generation" ''
        if [ -z "$1" ]; then
          echo "$0 <generation>"
          exit 1
        fi
        sudo nix-env --switch-generation $1 -p /nix/var/nix/profiles/system
        sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
      '')

      # Load Neovim with previous session setup
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

      # Helper script to merge passwords with Phone database
      (writeShellScriptBin "mergepasswords" ''
        machine=$(hostname)
        source=/data/sync/HomeDatabase.kdbx

        if [ "$machine" = "minoo" ]; then
          target=/mnt/suuno/sync/HomeDatabase.kdbx
          keepassxc-cli merge --same-credentials $source $target && cp $source $target
        else
          # TODO: Verify the below regex is correct for finding conflicting kdbx files
          fd "conflict.*HomeDatabase.kdbx" /data/sync -x keepassxc-cli merge --same-credentials $source
        fi
      '')

      # System and hardware information: lsusb, lspci, lscpu, lsblk
      usbutils
      pciutils
      cpu-x
      lshw
      btop                  # Sexy top

      # Utils
      exfatprogs            # Tools for managing exfat partitions on USB sticks (Use instead of fat32 as it has large file support).
      parted                # Disk partition tool
      nix-prefetch-github   # <owner> <repo> - Get SHA and REV of Github repo for e.g. youtube-dl (above)
      nvd                   # Nix diff versions (Used in ./build)
      nix-tree              # Tree view of Nix derivations
      inotify-tools
      libnotify             # notify-send "Backup Complete"
      ncdu                  # Tree-based, interactive du

      trashy                # Trash can cli tool - move files to trash can with alias to rm
      fd                    # Alternative to find, use fd <term> </start/path> -x <cmd> to run a command for each item found
      ripgrep
      unzip
      zip

      tipp10                # Typing Tutor
    ];
  };
}