# Host side of running Pacent production on minoo via Kamal (Docker): the Docker
# engine for the containers, the public web ports, the persistent volume
# directories, and a dynamic-DNS updater keeping pacent.fit pointed at the home
# IP. The app itself is deployed with Kamal from the pacent repo, not from here.
# See /data/code/pacent/docs/designs/2026-07-13-kamal-deployment.md.
{ config, lib, pkgs, ... }:
let
  # Point the pacent.fit apex A record at whatever public IP the request comes
  # from (the home connection), so DNS follows the DHCP-assigned IP. The Namecheap
  # dynamic-DNS password comes from nixx credentials at runtime (never baked into
  # the store), the same way mbsync's PassCmd fetches the mail password.
  ddnsUpdate = pkgs.writeShellApplication {
    name = "pacent-ddns-update";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      password="$(nixx credentials show namecheap_ddns.password)"
      if [ -z "$password" ]; then
        echo "namecheap_ddns.password missing from nixx credentials" >&2
        exit 1
      fi
      # Namecheap replies with XML; <ErrCount>0</ErrCount> means the update took.
      response="$(curl -sS "https://dynamicdns.park-your-domain.com/update?host=@&domain=pacent.fit&password=$password" || true)"
      if printf '%s' "$response" | grep -q "<ErrCount>0</ErrCount>"; then
        echo "pacent.fit A record updated"
      else
        echo "Namecheap DDNS update failed: $response" >&2
        exit 1
      fi
    '';
  };
in {
  # Docker engine for Kamal; phil deploys as a non-root user in the docker group.
  virtualisation.docker.enable = true;
  users.users.${config.username}.extraGroups = [ "docker" ];

  # Public web ports. kamal-proxy terminates TLS (Let's Encrypt) on 443 and serves
  # the HTTP-01 challenge on 80.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Persistent volume directories, bind-mounted into the container as uid 1000
  # (its rails user). App state (SQLite DBs, Garmin tokens) on the internal NVMe;
  # backups on the second disk (/data) so a backup and its source aren't on the
  # same drive. 0700 so only the container user can read them.
  systemd.tmpfiles.rules = [
    "d /var/lib/pacent 0700 1000 1000 -"
    "d /data/pacent 0755 1000 1000 -"
    "d /data/pacent/backups 0700 1000 1000 -"
  ];

  # Dynamic DNS: keep pacent.fit pointed at the home IP as it changes.
  systemd.services.pacent-ddns = {
    description = "Update pacent.fit A record at Namecheap (dynamic DNS)";
    # nixx (for the credential) lives in the system profile; system services don't
    # inherit the login SRC, so set it here so nixx finds the repo.
    environment = {
      PATH = lib.mkForce "/run/current-system/sw/bin:/run/wrappers/bin";
      SRC = "${config.codeDir}/nixfiles";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ddnsUpdate}/bin/pacent-ddns-update";
    };
  };
  systemd.timers.pacent-ddns = {
    description = "Periodic pacent.fit dynamic-DNS update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "10min";
      Persistent = true;
    };
  };
}
