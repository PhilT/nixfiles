{ config, lib, pkgs, ... }: {
  imports = [
  ] ++ lib.optional (builtins.pathExists ./work.nix) ./work.nix; # Copy from work.nix.example to use

  virtualisation.docker.enable = true;

  programs = {
    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a Ruby or .NET project)
    direnv.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
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

    etc = {
      "process-compose/theme.yaml".source = ../dotfiles/process-compose-theme.yaml;

      # TODO: disable_exit_confirmation does not work yet as I think devbox is using an
      # older version of process-compose. Hopefully this will be updated soon
      "process-compose/settings.yaml".text = ''
        theme: Custom Style
        sort:
          by: NAME
          isReversed: false
        disable_exit_confirmation: true
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "L+ ${config.xdgConfigHome}/process-compose - - - - /etc/process-compose"
  ];
}