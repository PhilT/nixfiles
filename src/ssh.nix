{ config, lib, pkgs, ... }:

let
  homeDir = config.users.users.${config.username}.home;
in
{
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
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
    "192.168.1.248".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGR9XFTdYSj2RkPy4OaAVJvzP5D5o9JbUUYzlK2zc/aX";
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