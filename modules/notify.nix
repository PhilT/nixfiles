# Email notifications for ZFS events (via zed) and systemd unit failures
# (via the notify-email@.service template). Reuses the existing himalaya
# SMTP config: credentials come from `nixx credentials show email_password`
# at send time, so no password ever lands in /etc or the nix store.
{ config, pkgs, lib, ... }:
let
  recipient = "@EMAIL@";

  # Slim himalaya config: no notmuch dependency, stub maildir backend so
  # himalaya is happy, SMTP block identical to the user-side config.
  himalayaConfig = pkgs.writeText "notify-himalaya.toml" ''
    [accounts.notify]
    default = true
    email = "${recipient}"

    backend.type = "maildir"
    backend.maildir-path = "/var/lib/notify/maildir"

    message.send.backend.type = "smtp"
    message.send.backend.host = "mail.privateemail.com"
    message.send.backend.port = 465
    message.send.backend.login = "${recipient}"
    message.send.backend.encryption.type = "tls"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.cmd = "/run/current-system/sw/bin/nixx credentials show email_password"
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
      Environment = "SRC=/data/code/nixfiles";
      ExecStart = "${notifyUnit}/bin/notify-email-unit %i";
    };
  };

  # ZFS event daemon — automatic notifications for pool/scrub/resilver events.
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ recipient ];
    ZED_EMAIL_PROG = "${zedMail}/bin/notify-email-zed";
    ZED_NOTIFY_VERBOSE = true;
  };
  systemd.services.zfs-zed.serviceConfig.Environment = "SRC=/data/code/nixfiles";
}
