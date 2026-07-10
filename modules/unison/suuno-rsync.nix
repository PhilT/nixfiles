# One-way media sync to/from suuno (the phone) over the sshfs mount.
#
# The phone's SSH server (Banana Studio) is SFTP-only and refuses command
# exec, so rsync cannot run remotely (no rsync-over-ssh). These jobs run rsync
# over the existing /mnt/suuno sshfs mount instead. rsync compares mtime+size
# and never re-reads file contents, so unlike unison it is not defeated by the
# phone's unstable synthetic inode numbers after a remount.
#
# Only the large, minoo-authoritative one-way trees live here. The bidirectional
# paths (documents, notes, sync, pictures/camera) stay on unison
# (modules/unison/suuno.nix).

{ config, pkgs, lib, ... }:
let
  user = "phil";
  data = config.dataDir; # /data
  mnt = "/mnt/suuno";
  rsync = "${pkgs.rsync}/bin/rsync";

  # Match the ignore set unison uses (see modules/unison/default.nix) so the
  # mirror leaves Android's regenerated .thumbnails cache alone (excluded files
  # are protected from --delete) and never pushes unison's leftover temp files.
  excludes = lib.concatMapStringsSep " " (p: "--exclude='${p}'") [
    ".thumbnails"
    "*.tmp"
    ".unison.*"
    "*.lock"
    ".DS_Store"
    "Thumbs.db"
    "desktop.ini"
  ];

  # FAT-family phone storage: no Unix perms/owner, coarse mtime granularity,
  # and directory mtimes that can't be preserved. --modify-window=1 tolerates
  # the mtime rounding; --no-perms/owner/group stop rsync setting Unix metadata;
  # --omit-dir-times stops it re-touching every directory's mtime each run.
  pushFlags = "-rt --omit-dir-times --delete --modify-window=1 --no-perms --no-owner --no-group --partial ${excludes}";

  # Offline phone is the normal case, not a failure. Ping first, exit 0 silently
  # if unreachable (same idea as the unison-failure-gate in default.nix).
  guard = ''
    if ! ${pkgs.iputils}/bin/ping -c1 -W3 suuno >/dev/null 2>&1; then
      echo "suuno offline, skipping"; exit 0
    fi
  '';

  pushPaths = [ "music" "music_extra" "pictures/showcase" "books" ];
  unitName = p: lib.replaceStrings [ "/" ] [ "-" ] p;

  pushService = p: {
    name = "suuno-push-${unitName p}";
    value = {
      description = "rsync push ${p} to suuno (mirror)";
      after = [ "mnt-suuno.mount" ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = "users";
        ExecStart = pkgs.writeShellScript "suuno-push-${unitName p}" ''
          ${guard}
          exec ${rsync} ${pushFlags} "${data}/${p}/" "${mnt}/${p}/"
        '';
      };
    };
  };

  pushTimer = p: {
    name = "suuno-push-${unitName p}";
    value = {
      description = "Periodic rsync push ${p} to suuno";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "10m";
        OnUnitInactiveSec = "30m";
        Persistent = true;
      };
    };
  };

  # Watch the local tree and fire the push on change, so minoo->phone edits
  # propagate within seconds instead of waiting for the timer. Runs as root
  # (not phil) because it calls `systemctl start` on a system unit, which a
  # non-root user can't do without a polkit agent. The push it starts still
  # runs as phil. Debounced: after the first event, wait for 10s of quiet
  # before pushing once, so a bulk import fires a single rsync.
  watchService = p: {
    name = "suuno-watch-${unitName p}";
    value = {
      description = "Watch ${data}/${p}, trigger rsync push to suuno on change";
      wantedBy = [ "multi-user.target" ];
      after = [ "mnt-suuno.mount" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = "5";
        ExecStart = pkgs.writeShellScript "suuno-watch-${unitName p}" ''
          dir=${lib.escapeShellArg "${data}/${p}"}
          iw=${pkgs.inotify-tools}/bin/inotifywait
          while "$iw" -r -q -e modify,create,delete,move "$dir"; do
            while "$iw" -r -q -t 10 -e modify,create,delete,move "$dir"; do :; done
            ${pkgs.systemd}/bin/systemctl start --no-block suuno-push-${unitName p}.service
          done
        '';
      };
    };
  };
in
{
  systemd.services =
    lib.listToAttrs (map pushService pushPaths)
    // lib.listToAttrs (map watchService pushPaths);
  systemd.timers = lib.listToAttrs (map pushTimer pushPaths);
}
