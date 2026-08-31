# work.nix is from work.nix.example and isn't versioned.

{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
    ./scripts/watcher.nix
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      claude-code = prev.stdenvNoCC.mkDerivation rec {
        pname = "claude-code";
        version = "2.1.247";

        src = prev.fetchurl {
          url = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${version}/linux-x64/claude";
          hash = "sha256-X7Mhv0F//FzU4/NufJx+Apv0eqo21WIduXn8xebqvhU=";
        };

        dontUnpack = true;
        dontBuild = true;
        dontStrip = true;

        nativeBuildInputs = [ prev.installShellFiles prev.makeBinaryWrapper prev.autoPatchelfHook ];

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/claude
          wrapProgram $out/bin/claude \
            --set DISABLE_AUTOUPDATER 1 \
            --set-default FORCE_AUTOUPDATE_PLUGINS 1 \
            --set DISABLE_INSTALLATION_CHECKS 1 \
            --set USE_BUILTIN_RIPGREP 0 \
            --prefix PATH : ${prev.lib.makeBinPath ([prev.procps prev.ripgrep]
              ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [prev.bubblewrap prev.socat])}
          runHook postInstall
        '';

        meta = prev.claude-code.meta or {};
      };
    })
  ];

  # Holds the Supermaven api_key, so it lives in a file bin/sync-to-public filters out of
  # the public repository rather than inline here where publishing would carry it.
  #
  # To rotate the key: ~/.supermaven/config.json is a symlink to this file (tmpfiles rule
  # below) and /etc/supermaven/config.json points into the nix store, so sm-agent's write
  # fails and it keeps the old key. Delete the symlink, open Neovim so sm-agent registers
  # and writes a fresh ~/.supermaven/config.json, copy that over config/supermaven.json,
  # then `nixx build -s`. If the symlink doesn't come back, `sudo systemd-tmpfiles --create`
  # restores it.
  environment.etc."supermaven/config.json".source = ../config/supermaven.json;

  environment.etc."claude-code/managed-settings.json".source = ../dotfiles/claude-settings.json;

  # Claude Code's hooks: the scripts that decide what every session in every repository is
  # allowed to do. They live here so a change to them is reviewed and has a history like the
  # rest of the machine. ~/.claude/hooks is a symlink to this, so settings.json keeps
  # invoking $HOME/.claude/hooks/<name>.sh, and an edit takes effect on `nixx build -s`.
  environment.etc."claude-code/hooks".source = ../claude/hooks;

  systemd.tmpfiles.rules = [
    "L+ ${config.homeDir}/.supermaven/config.json - - - - /etc/supermaven/config.json"
    "L+ ${config.homeDir}/.claude.json - - - - ${config.persistedHomeDir}/claude.json"
    "L+ ${config.homeDir}/.claude - - - - ${config.persistedHomeDir}/claude"
    "L+ ${config.persistedHomeDir}/claude/hooks - - - - /etc/claude-code/hooks"
  ];

  environment = {
    shellAliases = {
      rs = "rust-script";
    };

    sessionVariables = {
      # Fix issue with TailwindCSS 3 Chokidar causing the following error:
      # FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
      NODE_OPTIONS = "--max-old-space-size=8192";
    };

    systemPackages = with pkgs; [
      jq
      gh
      gcc
      claude-code
      lldb_21
      nodejs_22 # Claude requires Node.js < 24 (nodejs_20 is EOL/insecure in 26.05)

      # Language servers
      clang-tools
      csharp-ls
      dotnet-sdk_8
      fsautocomplete
      glsl_analyzer
      rust-analyzer
      terraform-ls
      typescript-language-server

      #(writeShellScriptBin "matter" ''
      #  cd $CODE/matter
      #  nix-shell shell.nix --run "nvim -S Session.vim"
      #'')

      #(writeShellScriptBin "gox" ''
      #  cd $CODE/matter
      #  nix-shell shell.nix --run "gox -s 2"
      #'')

      #(
      #  vscode-with-extensions.override {
      #    vscode = vscodium;
      #    vscodeExtensions = with vscode-extensions; [
      #      anthropic.claude-code
      #      asciidoctor.asciidoctor-vscode
      #      catppuccin.catppuccin-vsc
      #      catppuccin.catppuccin-vsc-icons
      #      gencer.html-slim-scss-css-class-completion
      #      ionide.ionide-fsharp
      #      jnoortheen.nix-ide
      #      rust-lang.rust-analyzer
      #      shopify.ruby-lsp
      #      supermaven.supermaven
      #      vscodevim.vim
      #      yzhang.markdown-all-in-one
      #    ];
      #  }
      #)
    ];
  };
}