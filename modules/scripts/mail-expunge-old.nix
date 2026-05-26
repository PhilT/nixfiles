{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "mail-expunge-old" ''
      set -euo pipefail

      # Phase 7 reclaim: move messages older than 5 years from live folders
      # (INBOX, Newsletters, Sent) into Archive/<year>/, then run mbsync with
      # a one-shot `Expunge Both` override to actually purge the originals
      # from IMAP. Run MANUALLY — never on a timer. Run on one client at a
      # time, then `sync_minoo_mail` on the others to converge.
      #
      # Usage:
      #   mail-expunge-old [--dry-run]

      DRY_RUN=0
      case "''${1:-}" in
        --dry-run) DRY_RUN=1 ;;
        "") ;;
        *) echo "usage: mail-expunge-old [--dry-run]" >&2; exit 64 ;;
      esac

      # Hold the same local flock that mail-sync uses so the periodic timer
      # can't fire an `mbsync namecheap` in the middle of our expunge run.
      LOCAL_LOCK="''${XDG_RUNTIME_DIR:-/tmp}/mail-sync.lock"
      exec 7>"$LOCAL_LOCK"
      if ! ${pkgs.util-linux}/bin/flock -n 7; then
        echo "mail-sync is currently running; try again in a moment" >&2
        exit 1
      fi

      MAILROOT=/data/mail/namecheap
      # Cutoff is the calendar year 5 years back. Anything with a Date: header
      # year strictly less than this is eligible. Using Date: (not filename or
      # mtime) because mbsync's filename epoch is the download time, not when
      # the message was sent.
      CUTOFF_YEAR=$(${pkgs.coreutils}/bin/date -d '5 years ago' +%Y)

      # Years already excluded from mbsync Patterns are the only safe move
      # targets: a message moved into Archive/<live year> would be
      # re-uploaded to IMAP on the next sync.
      COLD_YEARS=$(${pkgs.gnugrep}/bin/grep -oE '!Archive/[0-9]{4}' /etc/mbsyncrc \
                     | ${pkgs.gnused}/bin/sed 's|!Archive/||' | sort -u | tr '\n' ' ')

      # Eligible source folders: Newsletters, Sent, plus every live (non-cold)
      # Archive/<year>. INBOX is intentionally excluded — workflow is that
      # INBOX holds unactioned mail, anything that stays old in INBOX is a
      # bug not a candidate for expunge.
      ELIGIBLE=(Newsletters Sent)
      # Archive itself is also a Maildir (messages dropped directly there, not
      # inside a year subdir) — include if it has its own cur/new.
      [ -d "$MAILROOT/Archive/cur" ] && ELIGIBLE+=("Archive")
      for d in "$MAILROOT"/Archive/*/; do
        year=$(basename "$d")
        [[ "$year" =~ ^[0-9]{4}$ ]] || continue
        if ! echo " $COLD_YEARS " | ${pkgs.gnugrep}/bin/grep -q " $year "; then
          ELIGIBLE+=("Archive/$year")
        fi
      done

      echo "cutoff: messages with Date: year < $CUTOFF_YEAR"
      echo "cold target years: $COLD_YEARS"
      echo "eligible source folders: ''${ELIGIBLE[*]}"
      [ "$DRY_RUN" = 1 ] && echo "*** dry-run mode ***"
      echo

      moved=0
      skipped=0

      for folder in "''${ELIGIBLE[@]}"; do
        for sub in cur new; do
          dir="$MAILROOT/$folder/$sub"
          [ -d "$dir" ] || continue
          for src in "$dir"/*; do
            [ -f "$src" ] || continue

            base=$(basename "$src")

            # Year from message Date: header. Skip if unparseable or recent.
            # grep returns 1 when there's no match; under set -e + pipefail
            # that would kill the script, so guard each step.
            year=""
            if date_line=$(${pkgs.gnugrep}/bin/grep -m1 -i '^Date:' "$src" 2>/dev/null); then
              year=$(echo "$date_line" | ${pkgs.gnugrep}/bin/grep -oE '(19|20)[0-9]{2}' | head -1 || true)
            fi
            [[ "$year" =~ ^[0-9]{4}$ ]] || continue
            [ "$year" -lt "$CUTOFF_YEAR" ] || continue

            if ! echo " $COLD_YEARS " | ${pkgs.gnugrep}/bin/grep -q " $year "; then
              echo "skip: $folder/$sub/$base would land in Archive/$year (not in mbsyncrc exclusions)"
              skipped=$((skipped+1))
              continue
            fi

            dest_dir="$MAILROOT/Archive/$year/cur"
            stripped=$(echo "$base" | ${pkgs.gnused}/bin/sed 's/,U=[0-9]\+//')
            dest="$dest_dir/$stripped"

            if [ "$DRY_RUN" = 1 ]; then
              echo "would move: $folder/$sub/$base -> Archive/$year/cur/$stripped"
            else
              mkdir -p "$dest_dir"
              ${pkgs.coreutils}/bin/mv "$src" "$dest"
            fi
            moved=$((moved+1))
          done
        done
      done

      echo
      echo "moved: $moved   skipped: $skipped"
      [ "$moved" -eq 0 ] && exit 0
      [ "$DRY_RUN" = 1 ] && { echo "dry-run: nothing changed"; exit 0; }

      # Safety ordering: push the moved files to minoo BEFORE telling IMAP to
      # expunge. At the moment of expunge there are 3 copies (this client's
      # Archive, minoo's backup, IMAP). If sync_minoo_mail fails, set -e
      # aborts and IMAP is never touched.
      echo
      echo "==> pushing cold archive to minoo (must succeed before IMAP expunge)..."
      /run/current-system/sw/bin/sync_minoo_mail -batch

      echo
      echo "==> running mbsync with Expunge Both to purge IMAP..."
      tmpconfig=$(${pkgs.coreutils}/bin/mktemp)
      trap "rm -f '$tmpconfig'" EXIT
      ${pkgs.gnused}/bin/sed 's/^Expunge Near$/Expunge Both/' /etc/mbsyncrc > "$tmpconfig"
      ${pkgs.isync}/bin/mbsync -c "$tmpconfig" namecheap

      ${pkgs.notmuch}/bin/notmuch new

      cat <<'WARN'

==> done on this host.
    Run on EACH OTHER client (e.g. aramid) to converge:
        sync_minoo_mail
    That pulls the cold-archive copies of the moved messages.
WARN
    '')
  ];
}
