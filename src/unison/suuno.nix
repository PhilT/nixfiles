# Sync Unison with Suuno
# Runs on Minoo

{ config, lib, pkgs, ... }:

let
  mountsConfig = lib.lists.foldr (path: str: "mountpoint = ${path}\n${str}") "";
in
{
  imports = [ ./default.nix ];

  unison = {
    target = "suuno";
    paths = [
      "books"
      "documents"
      "music"
      "music_extra"
      "notes"
      "pictures/showcase"
      "pictures/camera"
      "sync"
      "txt"
    ];
    extraConfig = ''
      perms = 0
      dontchmod = true

      ${mountsConfig config.unison.paths}
      forcepartial = Path pictures/showcase /data
      forcepartial = Path music /data
    '';
    waitFor = [ "network-online.target" "mnt-suuno.mount" ];
  };

  # TODO: Confirm whether this is needed
  programs.fuse.userAllowOther = true;

  fileSystems."/mnt/suuno" = {
    device = "phil@suuno:/";
    fsType = "fuse.sshfs";
    options = [
      "port=2222"
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
      "allow_other"
      "IdentityFile=${config.etcDir}/ssh/ssh_host_ecdsa_key"
      "uid=${toString config.users.users.phil.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "umask=0022"    # Set permissions so files are accessible as needed
      "x-systemd.automount"  # enables automounting on access
      # Optionally, add "x-systemd.idle-timeout=10sec" to unmount after inactivity
    ];
  };

  environment.systemPackages = with pkgs; [
    sshfs

    (writeShellScriptBin "sync_${config.unison.target}" ''
      UNISON=${config.environment.variables.UNISON} ${pkgs.unison}/bin/unison ${config.dataDir} /mnt/${config.unison.target} -include common $@
    '')
  ];

  systemd.tmpfiles.rules = [
    "d /mnt/${config.unison.target} - ${config.username} users -"
  ];
}