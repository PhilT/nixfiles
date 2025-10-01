# work.nix is from work.nix.example and isn't versioned.

{ config, lib, pkgs, ... }: {
  imports = [
    ./devbox.nix
  ] ++ lib.optional (builtins.pathExists /data/work/work.nix) /data/work/work.nix;

  virtualisation.docker.enable = true;

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
    systemPackages = with pkgs; [
      jq
      gcc
      claude-code
      lldb_21
      ollama
      nodejs_20 # Claude requires Node.js < 24

      # Ollama setup script
      (writeShellScriptBin "ollama-setup" ''
        echo "Setting up Ollama with nomic embed model..."

        # Start ollama service if not running
        if ! pgrep -x ollama >/dev/null; then
          echo "Starting Ollama service..."
          ollama serve &
          sleep 3
        else
          echo "Ollama service is already running"
        fi

        # Check if nomic embed model is available
        if ! ollama list | grep -q "nomic-embed-text"; then
          echo "Downloading nomic embed model..."
          ollama pull nomic-embed-text
        else
          echo "Nomic embed model already available"
        fi

        echo ""
        echo "Ollama setup complete!"
        echo "- Service: http://localhost:11434"
        echo "- Model: nomic-embed-text"
        echo ""
        echo "Usage:"
        echo "  ollama run nomic-embed-text"
        echo "  curl http://localhost:11434/api/embeddings -d '{\"model\":\"nomic-embed-text\",\"prompt\":\"your text\"}'"
        echo ""
        echo "To stop: pkill ollama"
      '')

      (writeShellScriptBin "milvus-standalone" ''
        cd /data/milvus-vector-db

        echo "Starting Milvus with docker compose..."
        docker compose up -d

        echo ""
        echo "Milvus standalone stack started!"
        echo "- Milvus API: localhost:19530"
        echo "- Milvus Web UI: localhost:9091"
        echo "- MinIO Console: localhost:9001 (minioadmin/minioadmin)"
        echo ""
        echo "Check status:"
        echo "  cd /data/milvus-vector-db && docker compose logs"
        echo "  cd /data/milvus-vector-db && docker compose ps"
        echo ""
        echo "To stop all:"
        echo "  cd /data/milvus-vector-db && docker compose down"
      '')

      # Language servers
      clang-tools
      csharp-ls
      dotnet-sdk_8
      fsautocomplete
      glslls          # GLSL Language Server
      rust-analyzer
      terraform-ls

      #(writeShellScriptBin "matter" ''
      #  cd $CODE/matter
      #  nix-shell shell.nix --run "nvim -S Session.vim"
      #'')

      (writeShellScriptBin "gox" ''
        cd $CODE/matter
        nix-shell shell.nix --run "gox -s 2"
      '')

      (
        vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = with vscode-extensions; [
            anthropic.claude-code
            asciidoctor.asciidoctor-vscode
            catppuccin.catppuccin-vsc
            catppuccin.catppuccin-vsc-icons
            gencer.html-slim-scss-css-class-completion
            ionide.ionide-fsharp
            jnoortheen.nix-ide
            rust-lang.rust-analyzer
            shopify.ruby-lsp
            supermaven.supermaven
            vscodevim.vim
            yzhang.markdown-all-in-one
          ];
        }
      )
    ];
  };
}