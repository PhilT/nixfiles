# Copy of Sirius config, tweaked to work with the Lenovo X1 Carbon.

{ config, lib, pkgs, ... }:
let
  # Suuno is my phone, so it drops off the network constantly and unison fails
  # as expected. Only notify when suuno is actually reachable but unison still
  # failed — a genuine problem (e.g. SSH/port 2222 down) rather than the phone
  # simply being away. notify comes from modules/notify.nix (on PATH).
  unisonFailureGate = pkgs.writeShellApplication {
    name = "unison-failure-gate";
    runtimeInputs = [ pkgs.iputils pkgs.coreutils pkgs.systemd ];
    text = ''
      if ! ping -c1 -W3 suuno >/dev/null 2>&1; then
        exit 0  # phone offline — expected, stay silent
      fi
      port_state="reachable"
      if ! timeout 3 bash -c 'exec 3<>/dev/tcp/suuno/2222' >/dev/null 2>&1; then
        port_state="UNREACHABLE"
      fi
      body=$(journalctl -u unison.service --no-pager -n 50 2>&1 || echo "(no journal)")
      notify system "Service failed: unison (suuno up, port 2222 $port_state)" "$body"
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

  # Gate unison failure notifications on suuno actually being reachable (see above).
  systemd.services.unison.unitConfig.OnFailure = [ "unison-failure-notify.service" ];
  systemd.services.unison-failure-notify = {
    description = "Gated ntfy notification for unison failures (silent when suuno is offline)";
    serviceConfig = {
      Type = "oneshot";
      # notify curls localhost:2586; needs curl + hostname on PATH.
      Environment = [ "PATH=/run/current-system/sw/bin" ];
      ExecStart = "${unisonFailureGate}/bin/unison-failure-gate";
    };
  };

  # kmscon (enabled in modules/fonts.nix) takes tty1 with --no-switchvt and
  # blocks kodi from claiming the console. Disable it here.
  services.kmscon.enable = lib.mkForce false;

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