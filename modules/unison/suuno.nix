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
    # Only the small bidirectional paths stay on unison. The large one-way
    # trees (music, music_extra, pictures/showcase, books) are pushed by rsync
    # over the same mount (hosts/minoo/suuno-rsync.nix): rsync compares
    # mtime+size, so unlike unison it never re-reads the tree after a remount
    # churns sshfs's synthetic inodes. pictures/camera stays here because the
    # filing workflow relies on minoo->phone deletion propagation.
    paths = [
      "documents"
      "notes"
      "sync"
      "pictures/camera"
    ];
    extraConfig = ''
      perms = 0
      dontchmod = true

      ${mountsConfig config.unison.paths}
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
      "workaround=rename"
      # suuno is a phone that drops off wifi constantly, so favour fast reconnect:
      # 15s * 3 = 45s of silence before ssh tears down and reconnects.
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