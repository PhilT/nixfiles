# work.nix is from work.nix.example and isn't versioned.
# This one is synced with Unison.

{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

  environment = {
    # TODO: MOVE TO STUDIO?
    sessionVariables = {
      VST_PATH = "/run/current-system/sw/lib/vst/";
      VST3_PATH = "/run/current-system/sw/lib/vst3/";
    };

    systemPackages = with pkgs; [
      docker-compose # TODO: Should be able to remove once process-compose is rolled out
      godot

      # TODO: MOVE TO STUDIO?
      renoise
      helm
      surge-XT

      # VST plugins
      (callPackage ./vst/sala.nix {})
      # (callPackage ./vst/ot_piano_s.nix {})

      (writeShellScriptBin "matter" ''
        cd $CODE/matter
        nix-shell shell.nix --run "nvim -S Session.vim"
      '')

      (writeShellScriptBin "gox" ''
        cd $CODE/matter
        nix-shell shell.nix --run "gox -s 2"
      '')
    ];

  };
}