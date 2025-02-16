# Sync Unison with Minoo
# Runs on Spruce and Aramid

{ config, pkgs, lib, ... }:
{
  imports = [ ./default.nix ];

  unison = {
    target = "minoo";
    paths = [
      "books"
      "documents"
      "Claudi"
      "code/archive"
      "code/spikes"
      "music"
      "music_extra"
      "notes"
      "other"
      "pictures"
      "screenshots"
      "studio"
      "sync"
      "txt"
      "videos"
      "work"
    ];
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sync_${config.unison.target}" ''
      UNISON=${config.environment.variables.UNISON} ${pkgs.unison}/bin/unison ${config.dataDir} ssh://${config.unison.target}/${config.dataDir} -include common $@
    '')
  ];
}