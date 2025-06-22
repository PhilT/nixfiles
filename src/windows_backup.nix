{
  systemd.services.rsync-backup = {
    enable = true;
    description = "Run rsync backup for Windows vdisk at boot";
    wantedBy = [ "multi-user.target" ]; # Ensures it runs at system startup
    after = [ "network-online.target" ]; # Wait for network if needed
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot"; # Run once and exit
      User = "phil"; # Replace with the user that should run rsync
      ExecStart = ''
        /run/current-system/sw/bin/rsync -e /run/current-system/sw/bin/ssh \
          --inplace /data/vdisks/sapling.qcow2 phil@minoo:/data/vdisks/sapling.qcow2
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