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

  programs.ssh.knownHosts = {
    "github.com".publicKey = " ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
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

  # Used by Unison to authorize connection to each other
  # Also copied to phone (should be available in /etc/ssh/authorized_keys)
  users.users."${config.username}".openssh.authorizedKeys.keys = [
    (builtins.readFile ../secrets/id_ed25519_spruce.pub)
    (builtins.readFile ../secrets/id_ed25519_aramid.pub)
    (builtins.readFile ../secrets/id_ed25519_sapling.pub)
  ];
}