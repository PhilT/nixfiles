{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
  ] ++ lib.optional (builtins.pathExists ./work.nix) ./work.nix; # Copy from work.nix.example to use

  virtualisation.docker.enable = true;

  environment = {
    systemPackages = with pkgs; [
      docker-compose # TODO: Should be able to remove once process-compose is rolled out
      #quickemu # FIXME: Broken package

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