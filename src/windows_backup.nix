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
}