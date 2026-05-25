{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-sync" ''
      set -euo pipefail

      # IMAP is the source of truth for live mail. mbsync ↔ IMAP is the only
      # cross-machine transport — no unison and no remote lock here, both of
      # which caused resurrection / state-drift bugs when files with
      # client-local UID hints crossed machines via the server replica.
      # `sync_minoo_mail` (cold-archive backup) is a separate command.

      LOCAL_LOCK="''${XDG_RUNTIME_DIR:-/tmp}/mail-sync.lock"

      log() { echo "[mail-sync $(date +%H:%M:%S)] $*"; }

      # Local re-entrancy: overlapping timer ticks become no-ops.
      exec 7>"$LOCAL_LOCK"
      if ! ${pkgs.util-linux}/bin/flock -n 7; then
        log "another mail-sync is already running locally, exiting"
        exit 0
      fi

      ${pkgs.isync}/bin/mbsync namecheap
      ${pkgs.notmuch}/bin/notmuch new
    '')
  ];
}
