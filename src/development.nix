# work.nix is from work.nix.example and isn't versioned.
# This one is synced with Unison.

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
  ];

  environment = {
    systemPackages = with pkgs; [
      jq
      gcc
      claude-code
      lldb_21

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