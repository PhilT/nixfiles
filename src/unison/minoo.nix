# Sync Unison with Minoo
# Runs on Spruce and Aramid

{ config, pkgs, lib, ... }:
{
  imports = [ ./default.nix ];

  unison = {
    target = "minoo";
    paths = [
      "Claudi"
      "books"
      "calibre_library" # TODO: Merge books and calibre_library - Just have a calibre library called books/
      "code/archive"
      "code/spikes"
      "documents"
      "downloads"
      "home"
      "iso"
      "music"
      "music_extra"
      "notes"
      "other"
      "pictures"
      "screenshots"
      "studio"
      "sync"
      "txt"
      "vdisks"
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