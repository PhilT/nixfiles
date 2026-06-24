# Push notifications via the self-hosted ntfy server (see modules/ntfy.nix).
# Covers ZFS events (zed), systemd unit failures (notify@.service template),
# and zpool health (zpool-health-check timer). All publish to the `system`
# topic on the local ntfy server. The server's cache lives on the root pool,
# so alerts about a suspended dpool still send and replay when the phone
# returns to home Wi-Fi.
{ config, pkgs, lib, ... }:
let
  ntfyUrl = "http://localhost:2586";

  # notify <topic> "Title" [body]   — body defaults to stdin.
  # Failure-type alerts use high priority + warning tag.
  notify = pkgs.writeShellApplication {
    name = "notify";
    runtimeInputs = [ pkgs.curl pkgs.coreutils ];
    text = ''
      topic="$1"
      title="$2"
      body="''${3:-$(cat)}"
      host=$(hostname)
      curl -s \
        -H "Title: [$host] $title" \
        -H "Priority: high" \
        -H "Tags: warning" \
        -d "$body" \
        "${ntfyUrl}/$topic" > /dev/null
    '';
  };

  # ExecStart for notify@<unit>.service — builds body from the unit's journal.
  notifyUnit = pkgs.writeShellApplication {
    name = "notify-unit";
    runtimeInputs = [ pkgs.systemd notify ];
    text = ''
      unit="$1"
      body=$(journalctl -u "$unit" --no-pager -n 50 2>&1 || echo "(no journal)")
      notify system "Service failed: $unit" "$body"
    '';
  };

  # zed invokes: prog -s SUBJECT TO_ADDR   with body on stdin.
  zedNotify = pkgs.writeShellApplication {
    name = "notify-zed";
    runtimeInputs = [ notify ];
    text = ''
      subject="$2"
      notify system "ZFS: $subject"
    '';
  };

  # Alert on pool health transitions. The flag file records "alert sent"; it is
  # only touched after notify succeeds (set -e aborts first on a failed send),
  # so a failed send is retried on the next timer run.
  zpoolHealthCheck = pkgs.writeShellApplication {
    name = "zpool-health-check";
    runtimeInputs = [ pkgs.coreutils pkgs.zfs notify ];
    text = ''
      flag=/var/lib/notify/zpool-unhealthy
      state=$(zpool status -x)
      if [ "$state" = "all pools are healthy" ]; then
        if [ -e "$flag" ]; then
          printf '%s\n' "$state" | notify system "ZFS pools recovered"
          rm -f "$flag"
        fi
      else
        if [ ! -e "$flag" ]; then
          zpool status | notify system "ZFS pool UNHEALTHY"
          : > "$flag"
        fi
      fi
    '';
  };
in {
  environment.systemPackages = [ notify ];

  # Flag-file dir for the zpool watchdog (root pool).
  systemd.tmpfiles.rules = [
    "d /var/lib/notify 0700 root root -"
  ];

  # Opt-in OnFailure target. Use on any service you want to be notified about:
  #   systemd.services.foo.unitConfig.OnFailure = [ "notify@%n.service" ];
  systemd.services."notify@" = {
    description = "ntfy notification for failed unit %i";
    serviceConfig = {
      Type = "oneshot";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${notifyUnit}/bin/notify-unit %i";
    };
  };

  # ZFS event daemon — automatic notifications for pool/scrub/resilver events.
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = "${zedNotify}/bin/notify-zed";
    ZED_NOTIFY_VERBOSE = true;
  };
  systemd.services.zfs-zed.serviceConfig.Environment = [
    "PATH=/run/current-system/sw/bin"
  ];

  # Watchdog: a suspended/degraded pool does NOT make unison fail (it hangs in
  # uninterruptible I/O while systemd still sees it "active"), so OnFailure
  # can't catch it. Poll pool health directly and alert on transitions.
  systemd.services.zpool-health-check = {
    description = "Alert on unhealthy ZFS pools";
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = "2min";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${zpoolHealthCheck}/bin/zpool-health-check";
    };
  };
  systemd.timers.zpool-health-check = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/10";
  };
}
