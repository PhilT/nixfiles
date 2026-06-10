# Email notifications for ZFS events (via zed), systemd unit failures (via the
# notify-email@.service template), and pool health (via the zpool-health-check
# timer). The SMTP password is cached to /var/lib/notify/email_password on the
# always-online root pool at boot (notify-credentials.service) and read from
# there at send time. This deliberately avoids reading the credential from
# /data at send time: /data lives on dpool, and a notification about dpool being
# suspended must not depend on dpool being readable.
{ config, pkgs, lib, ... }:
let
  recipient = "@EMAIL@";

  # Cached SMTP password, on the root pool so the notifier never depends on dpool.
  passwordFile = "/var/lib/notify/email_password";

  # Slim himalaya config: no notmuch dependency, stub maildir backend so
  # himalaya is happy, SMTP block identical to the user-side config.
  himalayaConfig = pkgs.writeText "notify-himalaya.toml" ''
    [accounts.notify]
    default = true
    email = "${recipient}"

    backend.type = "maildir"
    backend.root-dir = "/var/lib/notify/maildir"

    message.send.backend.type = "smtp"
    message.send.backend.host = "mail.privateemail.com"
    message.send.backend.port = 465
    message.send.backend.login = "${recipient}"
    message.send.backend.encryption.type = "tls"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.cmd = "/run/current-system/sw/bin/cat ${passwordFile}"
    message.send.save-copy = false
  '';

  # notify-email "Subject" ["Body"]   — body defaults to stdin
  notifyEmail = pkgs.writeShellApplication {
    name = "notify-email";
    runtimeInputs = [ pkgs.himalaya pkgs.coreutils pkgs.inetutils ];
    text = ''
      subject="$1"
      body="''${2:-$(cat)}"
      host=$(hostname)
      {
        printf 'From: %s\n' "${recipient}"
        printf 'To: %s\n' "${recipient}"
        printf 'Subject: [%s] %s\n' "$host" "$subject"
        printf 'Date: %s\n\n' "$(date -R)"
        printf '%s\n' "$body"
      } | himalaya --config ${himalayaConfig} message send
    '';
  };

  # ExecStart for notify-email@<unit>.service
  notifyUnit = pkgs.writeShellApplication {
    name = "notify-email-unit";
    runtimeInputs = [ pkgs.systemd notifyEmail ];
    text = ''
      unit="$1"
      body=$(journalctl -u "$unit" --no-pager -n 50 2>&1 || echo "(no journal)")
      notify-email "Service failed: $unit" "$body"
    '';
  };

  # zed invokes: prog -s SUBJECT TO_ADDR   with body on stdin
  zedMail = pkgs.writeShellApplication {
    name = "notify-email-zed";
    runtimeInputs = [ notifyEmail ];
    text = ''
      subject="$2"
      notify-email "ZFS: $subject"
    '';
  };

  # Refresh the cached password. Write via temp file + mv: a plain redirect
  # would truncate the cache before nixx runs, and a failed refresh (dpool
  # down) must leave the previous password intact — the stale cache is what
  # lets us still send mail while dpool is suspended.
  cacheCredentials = pkgs.writeShellApplication {
    name = "notify-cache-credentials";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      umask 077
      tmp=$(mktemp /var/lib/notify/.email_password.XXXXXX)
      trap 'rm -f "$tmp"' EXIT
      nixx credentials show email_password > "$tmp"
      mv "$tmp" ${passwordFile}
    '';
  };

  # Alert on pool health transitions. The flag file records "alert sent"; it
  # is only touched after notify-email succeeds (set -e aborts first on a
  # failed send), so a failed send is retried on the next timer run.
  zpoolHealthCheck = pkgs.writeShellApplication {
    name = "zpool-health-check";
    runtimeInputs = [ pkgs.coreutils notifyEmail ];
    text = ''
      flag=/var/lib/notify/zpool-unhealthy
      state=$(zpool status -x)
      if [ "$state" = "all pools are healthy" ]; then
        if [ -e "$flag" ]; then
          printf '%s\n' "$state" | notify-email "ZFS pools recovered"
          rm -f "$flag"
        fi
      else
        if [ ! -e "$flag" ]; then
          zpool status | notify-email "ZFS pool UNHEALTHY"
          : > "$flag"
        fi
      fi
    '';
  };
in {
  environment.systemPackages = [ notifyEmail ];

  systemd.tmpfiles.rules = [
    "d /var/lib/notify 0700 root root -"
    "d /var/lib/notify/maildir 0700 root root -"
    "d /var/lib/notify/maildir/cur 0700 root root -"
    "d /var/lib/notify/maildir/new 0700 root root -"
    "d /var/lib/notify/maildir/tmp 0700 root root -"
  ];

  # Opt-in OnFailure target. Use on any service you want to be notified about:
  #   systemd.services.foo.unitConfig.OnFailure = [ "notify-email@%n.service" ];
  systemd.services."notify-email@" = {
    description = "Email notification for failed unit %i";
    serviceConfig = {
      Type = "oneshot";
      # himalaya runs auth.cmd via Command::new("sh"); needs sh on PATH.
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${notifyUnit}/bin/notify-email-unit %i";
    };
  };

  # ZFS event daemon — automatic notifications for pool/scrub/resilver events.
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ recipient ];
    ZED_EMAIL_PROG = "${zedMail}/bin/notify-email-zed";
    ZED_NOTIFY_VERBOSE = true;
  };
  systemd.services.zfs-zed.serviceConfig.Environment = [
    "PATH=/run/current-system/sw/bin"
  ];

  # Cache the SMTP password to the root pool at boot, while dpool is still
  # readable. Decrypting needs the credentials file on /data (dpool), so this
  # only refreshes when dpool is up; a stale cache is fine and is precisely what
  # lets us still send mail when dpool is suspended. Re-run manually after
  # rotating the password: systemctl start notify-credentials.
  systemd.services.notify-credentials = {
    description = "Cache SMTP password to root pool for notifications";
    # Requires+After on data.mount (/data is a legacy mountpoint, so
    # zfs-mount.service would not cover it).
    unitConfig.RequiresMountsFor = "/data/code/nixfiles";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # A suspended dpool blocks reads uninterruptibly, and multi-user.target
      # waits for this oneshot — without a timeout that would hang boot.
      # Failing is fine: the stale cache keeps notifications working.
      TimeoutStartSec = "2min";
      Environment = [
        "SRC=/data/code/nixfiles"
        "PATH=/run/current-system/sw/bin"
      ];
      ExecStart = "${cacheCredentials}/bin/notify-cache-credentials";
    };
  };

  # Watchdog: a suspended/degraded pool does NOT make unison fail (it hangs in
  # uninterruptible I/O while systemd still sees it "active"), so OnFailure
  # can't catch it. Poll pool health directly and alert on transitions.
  systemd.services.zpool-health-check = {
    description = "Alert on unhealthy ZFS pools";
    serviceConfig = {
      Type = "oneshot";
      # zpool status normally returns even on a suspended pool, but can hang on
      # a stuck spa_namespace_lock; without a timeout one hung run would leave
      # the unit "activating" forever.
      TimeoutStartSec = "2min";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${zpoolHealthCheck}/bin/zpool-health-check";
    };
  };
  systemd.timers.zpool-health-check = {
    wantedBy = [ "timers.target" ];
    # Wall-clock schedule: monotonic OnUnitActiveSec never re-arms if a run
    # hangs or fails, which would silently kill the watchdog.
    timerConfig.OnCalendar = "*:0/10";
  };
}
