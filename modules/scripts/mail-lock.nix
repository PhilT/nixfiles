{ pkgs, ... }: {
  # Diagnostic helpers for the mail-sync lock on minoo. The lock itself is
  # acquired and released by `mail-sync` for the duration of a cycle; these
  # are only for manual inspection / breaking a stale lock.
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-lock-status" ''
      set -euo pipefail
      ${pkgs.openssh}/bin/ssh minoo bash -s <<'REMOTE'
        lock="$HOME/mail.lock"
        if [ ! -e "$lock" ]; then
          echo "no lockfile"
          exit 0
        fi
        echo "contents:"
        cat "$lock" || true
        echo
        if flock -n "$lock" true 2>/dev/null; then
          echo "flock: FREE (stale contents — safe to clear)"
        else
          echo "flock: HELD"
        fi
      REMOTE
    '')

    (writeShellScriptBin "mail-lock-force-release" ''
      set -euo pipefail
      # Only safe if you have verified the holder is genuinely gone
      # (e.g. mail-lock-status reports FREE, or the named host is off).
      ${pkgs.openssh}/bin/ssh minoo bash -s <<'REMOTE'
        rm -f "$HOME/mail.lock"
        echo "removed mail.lock on minoo"
      REMOTE
    '')
  ];
}
