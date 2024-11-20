{ config, lib, pkgs, ... }:

let
  homeDir = config.users.users.${config.username}.home;
in
{
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_ecdsa_key";
        rounds = 100;
        type = "ecdsa";
      }
    ];
    settings = lib.mkIf config.ssh.preventRootLogin {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Client SSH program checks knownHosts when connecting to a server
  # This file is on the client
  programs.ssh.knownHosts = {
    "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    "minoo".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOWkHHuzy/5g47M7vI1FPL6lnZPGKJF1sd6m39y19Skp2gIPnlcyLt8671QgVDeXWisB78Bgm75XHatm0r5ECqc=";
    "suuno".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJGGiHFo6GiqCA3YKp58oP7RELGJ362G0aJyR0NgViu5";
  };

  programs.ssh.extraConfig = ''
    Host gitlab.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${homeDir}/.ssh/id_ed25519_gitlab

    Host github.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ${homeDir}/.ssh/id_ed25519_github
  '';

  # Used by Unison to authorize a connection from an incoming client.
  # This file is on the server.
  # Also copied to phone (should be available in /etc/ssh/authorized_keys)
  users.users."${config.username}".openssh.authorizedKeys.keys = [
    (builtins.readFile ../secrets/id_ed25519_spruce.pub)
    (builtins.readFile ../secrets/id_ed25519_aramid.pub)
    (builtins.readFile ../secrets/id_ed25519_sapling.pub)
    (builtins.readFile ../secrets/id_ed25519_minoo.pub)
  ];
}