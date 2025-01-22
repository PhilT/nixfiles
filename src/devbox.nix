{ config, lib, pkgs, ... }: {
  programs = {
    # Autorun nix-shell when entering a dir with a shell.nix (e.g. a Ruby or .NET project)
    #
    direnv.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      devbox
    ];

    etc = {
      "process-compose/theme.yaml".source = ../dotfiles/process-compose-theme.yaml;

      # TODO: Most of these settings do not work yet as I think devbox is using an
      # older version of process-compose. Hopefully this will be updated soon
      "process-compose/settings.yaml".text = ''
        theme: Custom Style
        sort:
          by: STATUS,NAME
          isReversed: false
        disable_exit_confirmation: true
      '';
    };
  };

  systemd.tmpfiles.rules = [
    "L+ ${config.xdgConfigHome}/process-compose - - - - /etc/process-compose"
  ];
}