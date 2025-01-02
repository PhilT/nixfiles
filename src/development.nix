{ config, lib, pkgs, ... }: {
  imports = [
  ] ++ lib.optional (builtins.pathExists ./work.nix) ./work.nix;

  virtualisation.docker.enable = true;

  programs = {
    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a Ruby or .NET project)
    direnv.enable = true;
  };

  environment.systemPackages = with pkgs; [
    docker-compose
    devbox
    quickemu

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
}