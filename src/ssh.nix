# I considered linking .ssh to the persistedHomeDir but actually this would
# result in knownHosts being updated should I connect to a new server which
# I don't want to persist between reboots. Additionally, we want the SSH dir
# to stick around (persist between boots) but it's unique to a machine so it
# belongs in /data/machine/.
{ config, lib, pkgs, ... }:
let
  HETZNER_SERVER_IP = "95.216.193.4";
in {
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    authorizedKeysFiles = [
      "${config.persistedMachineDir}/ssh/authorized_keys"
    ];
    # Not sure why we need these. Don't think I'm logging in as root anywhere
    hostKeys = [
      {
        path = "${config.etcDir}/ssh/ssh_host_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
      {
        path = "${config.etcDir}/ssh/ssh_host_ecdsa_key";
        rounds = 100;
        type = "ecdsa";
      }
    ];

    # Default is true - iso.nix overrides it to allow root login
    # on installation.
    settings = lib.mkIf config.ssh.preventRootLogin {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Client SSH program checks knownHosts when connecting to a server
  # This file is on the client at /etc/ssh/ssh_known_hosts
  # Hetzner is a root login e.g. ssh root@${HETZNER_SERVER_IP}
  # When looking up github.com /etc/ssh/ssh_known_hosts is checked
  # These keys can be retreived by doing e.g. `ssh-keyscan -t ed25519 github.com` or `ssh-keyscan -t ecdsa minoo`
  programs.ssh.knownHosts = {
    "${HETZNER_SERVER_IP}".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINo+WfA+c5sqnu/jPJN021gpfiVRRhxaYxKq7Kti9H7X";
    "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    "minoo".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOWkHHuzy/5g47M7vI1FPL6lnZPGKJF1sd6m39y19Skp2gIPnlcyLt8671QgVDeXWisB78Bgm75XHatm0r5ECqc=";
    "suuno".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGGiHFo6GiqCA3YKp58oP7RELGJ362G0aJyR0NgViu5";
  };

  # These options are applied while connecting to GitHub
  programs.ssh.extraConfig = ''
    Host ${HETZNER_SERVER_IP}
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedMachineDir}/ssh/id_ed25519_hetzner

    Host gitlab.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedMachineDir}/ssh/id_ed25519_gitlab

    Host github.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedMachineDir}/ssh/id_ed25519_github

    Host *
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedMachineDir}/ssh/id_ed25519
  '';

  # Used by Unison to authorize a connection from an incoming client.
  # This file is on the server.
  # Also copied to phone (should be available in /etc/ssh/authorized_keys)
  users.users."${config.username}".openssh.authorizedKeys.keys = [
    (builtins.readFile ../secrets/id_ed25519_spruce.pub)
    (builtins.readFile ../secrets/id_ed25519_aramid.pub)
    (builtins.readFile ../secrets/id_ed25519_sapling.pub)
    (builtins.readFile ../secrets/id_ed25519_seedling.pub)
    (builtins.readFile ../secrets/id_ed25519_minoo.pub)
  ];
}