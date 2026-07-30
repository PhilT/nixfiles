# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }:
let
  # Suuno is my phone, so it drops off the network constantly and unison fails
  # as expected. Only notify when suuno is actually reachable but unison still
  # failed — a genuine problem (e.g. SSH/port 2222 down) rather than the phone
  # simply being away. notify comes from modules/notify.nix (on PATH).
  #
  # One notification per outage: the flag file suppresses repeats until
  # unison-recovery-check sends the paired "recovered" message and clears it.
  # Touch-after-send ordering matches zpool-health-check in modules/notify.nix:
  # errexit aborts before the touch if the send fails, so it retries on the
  # next unit failure. $1 is the failing unit name (template instance, %n).
  unisonFailureGate = pkgs.writeShellApplication {
    name = "unison-failure-gate";
    runtimeInputs = [ pkgs.iputils pkgs.coreutils pkgs.systemd ];
    text = ''
      unit="$1"
      flag="/var/lib/notify/$unit.failed"
      if ! ping -c1 -W3 suuno >/dev/null 2>&1; then
        exit 0  # phone offline — expected, stay silent
      fi
      if [ -e "$flag" ]; then
        exit 0  # this outage has already been notified
      fi
      port_state="reachable"
      if ! timeout 3 bash -c 'exec 3<>/dev/tcp/suuno/2222' >/dev/null 2>&1; then
        port_state="UNREACHABLE"
      fi
      body=$(journalctl -u "$unit" --no-pager -n 50 2>&1 || echo "(no journal)")
      notify system "Service failed: $unit (suuno up, port 2222 $port_state)" "$body"
      touch "$flag"
    '';
  };

  # Pairs a "recovered" message with each notified failure: once a flagged unit
  # has been active for 3+ minutes it's past the fail-fast window (a broken
  # mount kills unison within seconds of a restart), so report and clear the
  # flag. Monotonic timestamps rather than date parsing: /proc/uptime and
  # ActiveEnterTimestampMonotonic share CLOCK_MONOTONIC.
  unisonRecoveryCheck = pkgs.writeShellApplication {
    name = "unison-recovery-check";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.systemd ];
    text = ''
      now_us=$(awk '{ printf "%d", $1 * 1000000 }' /proc/uptime)
      for flag in /var/lib/notify/*.failed; do
        [ -e "$flag" ] || continue
        unit=$(basename "$flag" .failed)
        systemctl is-active --quiet "$unit" || continue
        start_us=$(systemctl show -p ActiveEnterTimestampMonotonic --value "$unit")
        if [ -n "$start_us" ] && [ "$start_us" -gt 0 ] \
          && [ $((now_us - start_us)) -ge $((3 * 60 * 1000000)) ]; then
          notify system "Service recovered: $unit" "Active for 3+ minutes after the notified failure."
          rm -f "$flag"
        fi
      done
    '';
  };
in {
  imports = [
    ./minimal.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/common.nix

    # Sync
    # Not only does this provide a sync command to my phone but also
    # makes the unison command available for other machines to use.
    ../../modules/unison/suuno.nix
    ../../modules/unison/suuno-rsync.nix
    ../../modules/ssh.nix

    # Media Server/Player
    ./kodi_module.nix
    ./kodi.nix

    # Desktop
    ../../modules/desktop/light.nix

    # Running webservers
    ../../modules/devbox.nix

    # Push notifications (ntfy server + system-alert senders)
    ../../modules/ntfy.nix
    ../../modules/notify.nix

    # Pacent production (Docker/Kamal host, web ports, volumes, dynamic DNS)
    ./pacent.nix
  ];

  # Gate unison failure notifications on suuno actually being reachable, and
  # pair each notified failure with a recovery message (see above). Template
  # instance carries the failing unit name (same convention as notify@ in
  # modules/notify.nix), so the journal tail and outage flag are per-unit.
  systemd.services.unison.unitConfig.OnFailure = [ "unison-failure-notify@%n.service" ];
  systemd.services.unison-camera.unitConfig.OnFailure = [ "unison-failure-notify@%n.service" ];
  systemd.services."unison-failure-notify@" = {
    description = "Gated ntfy notification for failed %i (silent when suuno is offline)";
    serviceConfig = {
      Type = "oneshot";
      # notify curls localhost:2586; needs curl + hostname on PATH.
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${unisonFailureGate}/bin/unison-failure-gate %i";
    };
  };

  systemd.services.unison-recovery-notify = {
    description = "ntfy recovery notification for unison units with a notified failure";
    serviceConfig = {
      Type = "oneshot";
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${unisonRecoveryCheck}/bin/unison-recovery-check";
    };
  };
  systemd.timers.unison-recovery-notify = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
    };
  };

  # kmscon (enabled in modules/fonts.nix) takes tty1 with --no-switchvt and
  # blocks kodi from claiming the console. Disable it here.
  services.kmscon.enable = lib.mkForce false;

  # minoo is internet-exposed (router forwards 80/443 for pacent), so require a
  # password for sudo rather than the global passwordless default in base.nix:
  # code-exec as phil shouldn't be one step from root. Trade-off: non-interactive
  # `ssh minoo 'nixx build -s'` no longer works (sudo needs a tty); build with
  # `ssh -t` or at the console. NOTE: phil is still in the docker group here, which
  # is passwordless-root-equivalent, so this closes the sudo path but not that one.
  security.sudo.wheelNeedsPassword = lib.mkForce true;

  # How do we supply the key?
  # Need to change to keyfile instead of prompt?
  # Maybe not though, if permanently on and connected to the TV that
  # might enough to keep simple password login.
  # FIXME: Would be handy if I need to reboot it though to supply the password file
  # via SSH.

  hardware.graphics.enable = true; # TODO: Move into generic config

  # Unison watch on /data exceeds the default inotify ceiling.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 512;
  };

  # The dpool USB enclosure (SanDisk Extreme, ASMedia USB-NVMe bridge,
  # 0781:55ae) is unreliable under UAS: it aborts in-flight I/O and forces a
  # USB reset roughly every 30 min, which slowly accrues ZFS checksum errors
  # and, under scrub load, suspended the pool (Jun 2026). Force the bridge onto
  # bulk-only transport, which it handles reliably.
  boot.kernelParams = [ "usb-storage.quirks=0781:55ae:u" ];

  # smartd's default 30-min poll issues an ATA/NVMe pass-through the bridge
  # mishandles (it returns garbage SMART data and triggers the resets above).
  # Monitor only the internal boot NVMe; the USB drive can't be SMART-polled
  # reliably through this enclosure anyway. autodetect=false drops the default
  # DEVICESCAN line, which would otherwise still poll the USB drive.
  services.smartd.autodetect = false;
  services.smartd.devices = [ { device = "/dev/nvme0"; } ];
}