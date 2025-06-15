# work.nix is from work.nix.example and isn't versioned.
# This one is synced with Unison.

{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

  environment = {
    systemPackages = with pkgs; [
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