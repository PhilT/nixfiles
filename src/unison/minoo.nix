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
      "thunderbird_profile"
      "txt"
      "videos"
      "work"
    ];
  };

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sync_${config.unison.target}" ''
      ${pkgs.unison}/bin/unison ${config.dataDir} ssh://${config.unison.target}/${config.dataDir} -include common $@
    '')
  ];
}