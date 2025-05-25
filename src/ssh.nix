{ config, lib, pkgs, ... }:
let
  FABRIK_HETZNER_SERVER_IP = "95.216.193.4";
in {
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    authorizedKeysFiles = [
      "${config.persistedHomeDir}/ssh/authorized_keys"
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
  # This file is on the client
  programs.ssh.knownHosts = {
    "${FABRIK_HETZNER_SERVER_IP}".publicKey = (builtins.readFile ../secrets/id_ed25519_spruce_hetzner.pub);
    "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    "minoo".publicKey = (builtins.readFile ../secrets/id_ecdsa_minoo.pub);
    "suuno".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGGiHFo6GiqCA3YKp58oP7RELGJ362G0aJyR0NgViu5";
  };

  programs.ssh.extraConfig = ''
    Host ${FABRIK_HETZNER_SERVER_IP}
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedHomeDir}/ssh/id_ed25519_hetzner

    Host gitlab.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedHomeDir}/ssh/id_ed25519_gitlab

    Host github.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedHomeDir}/ssh/id_ed25519_github

    Host *
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${config.persistedHomeDir}/ssh/id_ed25519
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