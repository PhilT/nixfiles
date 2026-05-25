{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-archive" ''
      set -euo pipefail

      # Move one or more Maildir message files into Archive/<year>/cur, where
      # <year> is the message's Date header (falling back to file mtime if
      # unparseable). Then run a sync cycle so the change propagates.
      #
      # Usage: mail-archive <maildir-file> [<maildir-file>...]
      #
      # Intended to be bound to a key in himalaya or invoked directly with the
      # full path of a message file selected in the client.

      if [ $# -eq 0 ]; then
        echo "usage: mail-archive <maildir-file> [...]" >&2
        exit 64
      fi

      MAILROOT=/data/mail/namecheap

      for src in "$@"; do
        if [ ! -f "$src" ]; then
          echo "mail-archive: not a file: $src" >&2
          exit 1
        fi

        # Year from Date: header; fall back to mtime.
        year=$(${pkgs.gnused}/bin/sed -n 's/^Date: .* \([0-9]\{4\}\) .*/\1/p' "$src" | head -1)
        if [ -z "$year" ] || [ "$year" -lt 1990 ] || [ "$year" -gt 2100 ]; then
          year=$(${pkgs.coreutils}/bin/date -r "$src" +%Y)
        fi

        dest="$MAILROOT/Archive/$year/cur"
        if [ ! -d "$dest" ]; then
          echo "mail-archive: $dest does not exist (no IMAP folder for $year?)" >&2
          exit 1
        fi

        # mv within the same filesystem is atomic; mbsync on next cycle sees
        # the source as deleted and the dest as new, then reconciles to IMAP.
        ${pkgs.coreutils}/bin/mv "$src" "$dest/"
        echo "archived to Archive/$year: $(basename "$src")"
      done

      exec /run/current-system/sw/bin/mail-sync
    '')
  ];
}
