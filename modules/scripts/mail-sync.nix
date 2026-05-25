{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-sync" ''
      set -euo pipefail

      SERVER=minoo
      REMOTE_LOCK='$HOME/mail.lock'
      LOCAL_LOCK="''${XDG_RUNTIME_DIR:-/tmp}/mail-sync.lock"
      INFO="$(hostname):$$:$(date -Iseconds)"

      log() { echo "[mail-sync $(date +%H:%M:%S)] $*"; }

      # Local re-entrancy: overlapping timer ticks become no-ops.
      exec 7>"$LOCAL_LOCK"
      if ! ${pkgs.util-linux}/bin/flock -n 7; then
        log "another mail-sync is already running locally, exiting"
        exit 0
      fi

      # Network mode: LAN if minoo answers SSH, else away.
      if ${pkgs.openssh}/bin/ssh -q -o BatchMode=yes -o ConnectTimeout=5 \
           "$SERVER" true 2>/dev/null; then
        MODE=lan
      else
        MODE=away
      fi
      log "mode=$MODE"

      run_mbsync_notmuch() {
        ${pkgs.isync}/bin/mbsync namecheap
        ${pkgs.notmuch}/bin/notmuch new
      }

      if [ "$MODE" = away ]; then
        # Off-LAN: trust invariant 1, no lock, no unison.
        run_mbsync_notmuch
        exit 0
      fi

      # LAN: hold the server flock for the duration of the cycle.
      # The remote bash holds fd 9 on the lock file via flock, then reads stdin
      # forever. When we close the coproc's stdin the remote cat ends, the
      # subshell exits, fd 9 closes, and flock releases.
      coproc LOCK { ${pkgs.openssh}/bin/ssh "$SERVER" bash -s -- "$INFO" <<'REMOTE'
        info=$1
        lock="$HOME/mail.lock"
        exec 9<>"$lock"
        if ! flock -n 9; then
          echo "BUSY"
          cat "$lock" >&2 || true
          exit 1
        fi
        : >"$lock"
        printf '%s\n' "$info" >&9
        echo "OK"
        cat >/dev/null
REMOTE
      }

      read -r status <&"''${LOCK[0]}" || status=DEAD
      if [ "$status" != OK ]; then
        log "could not acquire $SERVER lock (status=$status)"
        ${pkgs.libnotify}/bin/notify-send -u critical \
          "mail-sync" "Lock held on $SERVER — see ~/mail.lock there" || true
        exit 1
      fi
      log "acquired lock on $SERVER"

      LOCK_HOLDER_PID="''${LOCK_PID:-}"
      release() {
        # SIGTERM on the ssh holder closes the channel; the remote bash exits,
        # fd 9 closes, and flock on minoo releases.
        if [ -n "''${LOCK_HOLDER_PID:-}" ]; then
          kill "$LOCK_HOLDER_PID" 2>/dev/null || true
          wait "$LOCK_HOLDER_PID" 2>/dev/null || true
        fi
        log "released lock"
      }
      trap release EXIT

      # The cycle.
      /run/current-system/sw/bin/sync_minoo_mail
      run_mbsync_notmuch
      /run/current-system/sw/bin/sync_minoo_mail
    '')
  ];
}
