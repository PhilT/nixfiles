{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
                                                              # Copy from work.nix.example
                                                              # This one is synced with Unison
                                                              # and ignored in VC.
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

  environment = {
    systemPackages = with pkgs; [
      docker-compose # TODO: Should be able to remove once process-compose is rolled out

      (writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '')


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