# Sync Unison with Minoo
# Runs on Spruce and Aramid
# Usage: sync_minoo -path path/to/sync

{ config, pkgs, lib, ... }:
{
  imports = [ ./default.nix ];

  unison = {
    target = "minoo";
    paths = [];
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sync_${config.unison.target}" ''
      UNISON=${config.environment.variables.UNISON} ${pkgs.unison}/bin/unison ${config.dataDir} ssh://${config.unison.target}/${config.dataDir} -include common $@
    '')
  ];
}