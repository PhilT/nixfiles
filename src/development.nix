# work.nix is from work.nix.example and isn't versioned.

{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
    ./scripts/watcher.nix
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      claude-code = prev.buildNpmPackage rec {
        pname = "claude-code";
        version = "2.1.81";

        src = prev.fetchzip {
          url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
          hash = "sha256-WT+fj9H/5hlr/U8MygiIdE2QZ32kRz6wTjYEABtmBPU=";
        };

        npmDepsHash = "sha256-x8Y1vODjATE6F6r0GhK427J0h2Et7bsqKoDcWaNO+IM=";

        postPatch = let
          packageLock = prev.fetchurl {
            url = "https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/by-name/cl/claude-code/package-lock.json";
            hash = "sha256-Bfiv//XNKAflWZxH2H9lqM4ZxXNw1kQIneX6d+nuMkg=";
          };
        in ''
          cp ${packageLock} package-lock.json
        '';

        dontNpmBuild = true;
        env.AUTHORIZED = "1";

        postInstall = ''
          wrapProgram $out/bin/claude \
            --set DISABLE_AUTOUPDATER 1 \
            --set DISABLE_INSTALLATION_CHECKS 1 \
            --unset DEV \
            --prefix PATH : ${prev.lib.makeBinPath ([prev.procps]
              ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [prev.bubblewrap prev.socat])}
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

  systemd.tmpfiles.rules = [
    "L+ ${config.homeDir}/.supermaven/config.json - - - - /etc/supermaven/config.json"
    "L+ ${config.homeDir}/.claude.json - - - - ${config.persistedHomeDir}/claude.json"
    "L+ ${config.homeDir}/.claude - - - - ${config.persistedHomeDir}/claude"
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
      gcc
      claude-code
      lldb_21
      nodejs_20 # Claude requires Node.js < 24
      uv        # Needed for Serena MCP

      # Language servers
      clang-tools
      csharp-ls
      dotnet-sdk_8
      fsautocomplete
      glsl_analyzer
      rust-analyzer
      terraform-ls

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