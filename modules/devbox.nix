{ config, lib, pkgs, ... }: {
  programs = {
    # Autorun nix-shell or devbox when entering a dir with a shell.nix (e.g. a Ruby or .NET project)
    #
    direnv.enable = true;
    direnv.silent = true;
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
          by: NAMESPACE,STATUS,NAME
          isReversed: false
        disable_exit_confirmation: true
      '';
    };
  };

  # Select the Node version from the nearest .node-version on every cd. fnm ships
  # inside project devbox environments rather than system-wide, so the function
  # no-ops until direnv has loaded one, and fnm env is sourced lazily on first use
  # so its PATH entry lands ahead of anything the devbox env set.
  programs.fish.interactiveShellInit = ''
    function __fnm_use_node --on-variable PWD
      command -q fnm; or return
      set -q FNM_MULTISHELL_PATH; or fnm env --shell fish | source
      fnm use --install-if-missing --silent-if-unchanged
    end

    # PWD does not change when a terminal opens directly inside a project, and
    # direnv has not run yet at this point, so run once after the first prompt.
    function __fnm_use_node_once --on-event fish_prompt
      functions -e __fnm_use_node_once
      __fnm_use_node
    end
  '';

  systemd.tmpfiles.rules = [
    "L+ ${config.xdgConfigHome}/process-compose - - - - /etc/process-compose"
  ];
}