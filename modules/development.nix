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

  environment.etc."supermaven/config.json" = {
    text = (builtins.toJSON {
      accepted_free_version = "true";
      api_key = "dtvwqqqlemljabfxyuzmgthixnsoexev";
      api_key_obtained_at = "2025-07-20 13:37:29.735744544";
      link_id = "pLd6OTY7pAKxtbXewm97XDvQKpfYfgJ7";
      machine_id = "11554dd9-2223-4d12-9eb2-8c96853eceb3";
    });
  };

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