{ config, pkgs, ... }:

{
#  nixpkgs.overlays = [
#    (self: super: {
#      godot_4 = super.godot_4.overrideAttrs (final: prev: {
#        sconsFlags = prev.sconsFlags ++ ([
#          "module_mono_enabled=yes"
#        ]);
#
#        nativeBuildInputs = prev.nativeBuildInputs ++ [ dotnet-sdk_6 ];
#
#        postInstall = ''
#          cp -r modules "$out/"
#          $out/bin/godot4 --headless --generate-mono-glue "$out/modules/mono/glue"
#          "$out/modules/mono/build_scripts/build_assemblies.py" --godot-output-dir="$out/bin" --godot-platform=linuxbsd
#        '';
#      });
#    })
#  ];

  programs = {
    # `j term` cd quickly
    autojump.enable = true;

    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a .NET project)
    direnv.enable = true;

    # xautolock also added in services
    slock.enable = true;

    # Starship - Highly configurable shell prompt
    starship.enable = true;

    bash.shellAliases = {
      ss = "feh -Z -F -D 15";
      invoice = "nix-shell $CODE/sheetzi/shell.nix --command $CODE/sheetzi/invoice";
    };
  };

  environment = {
    #sessionVariables = {
    #  DOTNET_ROOT = "${pkgs.dotnet-sdk_6}";
    #};

    systemPackages = with pkgs; [
      (callPackage ./studio.nix {})

      # Reset file/folder permissions
      (writeShellScriptBin "resetperms" ''
        find . -type d -print0 | xargs -0 chmod 755
        find . -type f -print0 | xargs -0 chmod 644
      '')

      #deadbeef-with-plugins # Music player
      cmus                  # Terminal based music player
      mpv                   # Video player
      #dotnet-sdk_6
      element-desktop       # Matrix chat client Connect to: #pimalaya.himalaya
      discord
      fd                    # Alternative to find
      feh
      flameshot             # Screnshot tool
      fsautocomplete
      gimp
      godot_4
      inkscape
      keepassxc
      libreoffice
      pinentry
      pulseaudio
      ripgrep
      shared-mime-info      # Recognise different file types
      slack
      surf
      unzip
      vengi-tools           # Voxel tools including VoxEdit
      whatsapp-for-linux
      wineWowPackages.full  # Needed for FL Studdio installer
      xclip                 # Used by Neovim among other things for copy/paste from/to system clipboard
      zip
    ];
  };
}
