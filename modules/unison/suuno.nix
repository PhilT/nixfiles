# Sync Unison with Suuno
# Runs on Minoo

{ config, lib, pkgs, ... }:

let
  mountsConfig = lib.lists.foldr (path: str: "mountpoint = ${path}\n${str}") "";

  # Adding or removing a file updates the parent directory's mtime, so one
  # remote getattr per minute detects phone-side camera changes without a
  # scan; the local stat catches minoo-side filing deletions. The 30-minute
  # unconditional pass covers what a dir mtime can't show (in-place edits) and
  # keeps us safe if Android's storage layer turns out not to bump dir mtime
  # for camera-app writes as seen over sshfs. When the phone is off wifi the
  # remote stat fails and the loop idles instead of unison restart-looping
  # against a dead mount.
  cameraCycle = pkgs.writeShellApplication {
    name = "unison-camera-cycle";
    runtimeInputs = with pkgs; [ unison coreutils ];
    text = ''
      remote=/mnt/${config.unison.target}/pictures/camera
      local_dir=${config.dataDir}/pictures/camera
      baseline=""
      last_sync=0
      while true; do
        remote_m=$(timeout 30 stat -c %Y "$remote" 2>/dev/null || echo "")
        local_m=$(stat -c %Y "$local_dir" 2>/dev/null || echo "")
        now=$(date +%s)
        if [ -n "$remote_m" ]; then
          if [ "$remote_m:$local_m" != "$baseline" ] || [ $((now - last_sync)) -ge 1800 ]; then
            unison camera
            last_sync=$(date +%s)
            remote_m=$(timeout 30 stat -c %Y "$remote" 2>/dev/null || echo "")
            local_m=$(stat -c %Y "$local_dir" 2>/dev/null || echo "")
            baseline="$remote_m:$local_m"
          fi
        fi
        sleep 60
      done
    '';
  };
in
{
  imports = [ ./default.nix ];

  unison = {
    target = "suuno";
    # Only the small bidirectional paths stay on unison. The large one-way
    # trees (music, music_extra, pictures/showcase, books) are pushed by rsync
    # over the same mount (hosts/minoo/suuno-rsync.nix): rsync compares
    # mtime+size, so unlike unison it never re-reads the tree after a remount
    # churns sshfs's synthetic inodes. pictures/camera has its own unison
    # service below with a faster cycle.
    paths = [
      "documents"
      "notes"
      "sync"
    ];
    # Writes made on the phone generate no inotify events through sshfs, so
    # watch mode only ever saw them at the startup scan. Scan periodically
    # instead: a full pass of these trees costs 45-60s over the mount; every
    # 30 minutes keeps the phone's SFTP duty cycle around 3%.
    repeat = "1800";
    extraConfig = ''
      perms = 0
      dontchmod = true

      ${mountsConfig config.unison.paths}
    '';
    waitFor = [ "network-online.target" "mnt-suuno.mount" ];
  };

  # pictures/camera is bidirectional (the filing workflow relies on
  # minoo->phone deletion propagation) but also where staleness is most
  # visible. It gets its own one-shot profile driven by unison-camera-cycle
  # (see the let binding above for the mtime-gated polling). Rooting at
  # pictures/ (not camera/) keeps the mountpoint guard: if the sshfs mount
  # presents an empty or missing tree, unison aborts instead of propagating
  # deletions. A distinct root pair also means a distinct archive, so no lock
  # contention with the main service.
  environment.etc."unison/camera.prf".text = ''
    root = ${config.dataDir}/pictures
    root = /mnt/${config.unison.target}/pictures
    path = camera
    mountpoint = camera

    batch = true
    dumbtty = true
    fastcheck = true
    times = true
    copyonconflict = true
    prefer = newer
    retry = 5

    perms = 0
    dontchmod = true

    ignore = Name .thumbnails
    ignore = Name *.tmp
  '';

  systemd.services.unison-camera = {
    enable = true;
    description = "Unison filesync for pictures/camera (mtime-gated 1-minute poll)";
    startLimitIntervalSec = 0;
    restartTriggers = [ config.environment.etc."unison/camera.prf".text ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${cameraCycle}/bin/unison-camera-cycle";
      Restart = "always";
      RestartSec = "5";
      RestartSteps = "10";
      RestartMaxDelaySec = "120";
      User = config.username;
      Group = "users";
    };
    environment.UNISON = "${config.persistedMachineDir}/unison";
    after = [ "network-online.target" "mnt-suuno.mount" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
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
    "L+ ${config.persistedMachineDir}/unison/camera.prf - - - - /etc/unison/camera.prf"
    "d ${config.dataDir}/pictures - ${config.username} users -"
    "d ${config.dataDir}/pictures/camera - ${config.username} users -"
  ];
}