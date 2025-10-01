{
  systemd.services.rsync-backup = {
    enable = true;
    description = "Run rsync backup for Windows vdisk at boot";
    after = [ "network-online.target" ]; # Wait for network connectivity
    wants = [ "network-online.target" ]; # Require network to be online
    serviceConfig = {
      Type = "oneshot"; # Run once and exit
      User = "phil"; # Replace with the user that should run rsync
      ExecStart = ''
        /run/current-system/sw/bin/rsync -e /run/current-system/sw/bin/ssh \
          --checksum --inplace /data/vdisks/sapling.qcow2 phil@minoo:/data/vdisks/sapling.qcow2
      '';
      ExecStartPost = ''
        /run/current-system/sw/bin/rsync -e /run/current-system/sw/bin/ssh \
          --checksum --dry-run /data/vdisks/sapling.qcow2 phil@minoo:/data/vdisks/sapling.qcow2 || \
          /run/current-system/sw/bin/systemd-cat -t rsync-backup echo "Backup verification failed"
      '';
    };
  };

  systemd.timers.rsync-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";         # Wait 5 minutes after boot
      AccuracySec = "1min";       # Acceptable delay window
      Persistent = true;          # Catch up if missed due to being powered off
    };
  };
}