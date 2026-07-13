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
  # Docker engine for Kamal. NixOS defaults the log driver to journald, but Kamal
  # passes `--log-opt max-size=10m` (a json-file/local option) to the proxy and app
  # containers, which journald rejects. json-file supports it and gives log rotation.
  virtualisation.docker = {
    enable = true;
    logDriver = "json-file";
  };

  # Dedicated deploy user for Kamal. Kamal runs its SSH commands through the login
  # shell and emits POSIX/bash syntax (e.g. `... || (echo; exit 1)`) that phil's
  # fish shell can't parse, so deploy uses bash. It authenticates with the same
  # keys as phil (openssh.authorizedKeysFiles is system-wide) and joins the docker
  # group to run the containers. The containers run as uid 987 (see below), so the
  # volume ownership is unaffected by which user invokes Docker.
  users.users.deploy = {
    isNormalUser = true;
    shell = pkgs.bashInteractive;
    extraGroups = [ "docker" ];
    # Same keys as phil (nixx drops these pubkeys to /tmp during the build), so
    # Kamal reaches deploy@minoo from spruce with the existing key.
    openssh.authorizedKeys.keys = [
      (builtins.readFile /tmp/id_ed25519_spruce.pub)
      (builtins.readFile /tmp/id_ed25519_aramid.pub)
      (builtins.readFile /tmp/id_ed25519_minoo.pub)
    ];
  };

  # Public web ports. kamal-proxy terminates TLS (Let's Encrypt) on 443 and serves
  # the HTTP-01 challenge on 80.
  #
  # This line only governs a non-container process binding 80/443. Docker publishes
  # kamal-proxy's ports with a DNAT rule evaluated before the nixos-fw (INPUT)
  # chain, so the container ports are reachable regardless of this setting; the
  # DOCKER-USER chain (currently empty) is where per-source filtering would go.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Dedicated unprivileged service user the pacent container runs as (uid 987 in
  # its image; see USER in the pacent Dockerfile). Deliberately NOT uid 1000: that
  # is phil, who has passwordless sudo and docker-group access, so a container
  # break-out as 1000 would land on the host as root. 987 owns only the volume
  # dirs below and has no shell, no groups and no sudo.
  users.groups.pacent.gid = 987;
  users.users.pacent = {
    isSystemUser = true;
    group = "pacent";
    uid = 987;
  };

  # Persistent volume directory, bind-mounted into the container as /rails/storage
  # and owned by the pacent service user (uid 987, matching USER in the image). App
  # state (SQLite DBs, Garmin tokens) lives on the internal NVMe. 0700 so only pacent
  # can read it.
  systemd.tmpfiles.rules = [
    "d /var/lib/pacent 0700 987 987 -"
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
