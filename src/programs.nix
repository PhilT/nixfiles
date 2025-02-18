# TODO: Consider merging with common.nix mirroring common_gui.nix
{ config, pkgs, ... }: {
  programs = {
    fish.enable = true;     # Fish! Shell
    starship.enable = true; # Starship - Highly configurable shell prompt
    neovim.enable = true;
    neovim.defaultEditor = true;
    git.enable = true;
    nix-ld.enable = true;
    nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries for unpackaged programs here
      # For now this is mostly for testing Pop (pop.com) screen sharing app
      # Use ldd <path to binary> to get a list
      xorg.libxshmfence
      glib
      nss
      nspr
      dbus
      at-spi2-atk
      libdrm
      gdk-pixbuf
      gtk3
      pango
      cairo
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      expat
      xorg.libxcb
      libxkbcommon
      mesa
      alsa-lib
      at-spi2-core
      cups
      xorg.libXtst
      openh264
    ];
  };

  environment = {
    shellAliases = {
      l = "ls -alh";
      ss = "imv -t 15 -f";
      fd = "fd -H";
      ls-packages = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq";
      ls-generations = "sudo nix-env -p /nix/var/nix/profiles/system --list-generations";
    };

    systemPackages = with pkgs; [
      # yt-dlp -x --audio-format mp3 https://URL
      yt-dlp

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
          fd "\\\(conflict.*HomeDatabase.kdbx" /data/sync -x keepassxc-cli merge --same-credentials $source
        fi
      '')

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

      fd                    # Alternative to find, use fd <term> </start/path> -x <cmd> to run a command for each item found
      ripgrep
      unzip
      zip
    ];
  };
}