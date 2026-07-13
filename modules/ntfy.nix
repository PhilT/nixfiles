# Self-hosted ntfy push-notification server (minoo, LAN-only). Replaces the
# former email notification path. State (cache DB) lives under /var/lib/ntfy-sh
# on the root pool via the module's systemd StateDirectory, so a suspended dpool
# never breaks alerting.
{ ... }: {
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "http://minoo:2586";  # include port so generated links resolve
      listen-http = ":2586";           # module default is 127.0.0.1:2586; bind all for LAN
      cache-duration = "720h";         # ~30 days, so missed alerts replay on return home
      behind-proxy = false;
    };
  };

  # Accept 2586 only on the LAN interface (minoo is on wlan0). Local senders
  # (modules/notify.nix) use localhost, which the firewall always allows on lo, so
  # they're unaffected. This keeps ntfy off the docker bridges and any future
  # interface (e.g. a VPN). ntfy has no auth, so the control against internet
  # exposure remains "only forward 80/443 at the router", never 2586.
  networking.firewall.interfaces.wlan0.allowedTCPPorts = [ 2586 ];
}
