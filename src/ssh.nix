{ config, lib, pkgs, ... }:

{
  services.fail2ban.enable = true;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  programs.ssh.extraConfig = ''
    Host gitlab.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ~/.ssh/id_ed25519_gitlab

    Host github.com
      IdentitiesOnly yes
      PreferredAuthentications publickey
      IdentityFile ~/.ssh/id_ed25519_github
  '';

  # Used by Unison to authorize connection to each other
  # Also copied to phone (should be available in /etc/ssh/authorized_keys)
  users.users."${config.username}".openssh.authorizedKeys.keys = [
    (builtins.readFile ../secrets/id_ed25519_spruce.pub)
    (builtins.readFile ../secrets/id_ed25519_aramid.pub)
  ];
}