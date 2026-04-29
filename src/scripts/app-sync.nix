{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "app-sync-minoo" ''

      app=$1
      direction=$2
      remote_path=phil@minoo:/data/home/$app/
      local_path=/data/home/$app/

      # Check if minoo is reachable
      if ! ${pkgs.openssh}/bin/ssh -q -o BatchMode=yes -o ConnectTimeout=5 minoo exit 2>/dev/null; then
        notify-send -u critical "$app profile sync" "minoo is not reachable, skipping sync"
        exit 1
      fi

      if [ $direction = to ]; then
        to=$remote_path
        from=$local_path
      else
        to=$local_path
        from=$remote_path
      fi

      if [ -f /data/home/$app/SingletonLock ]; then
        notify-send -u critical "Lock file found, skipping sync"
      else
        id=$(notify-send -p -t 18000000 "$app profile sync" "Syncing $direction minoo...")
        rsync -a --delete --exclude=Cache --exclude="Code Cache" --exclude=GPUCache --exclude=SingletonLock $from $to
        notify-send -r $id -t 5000 "$app profile sync" "Complete"
      fi
    '')

    (writeShellScriptBin "app-sync" ''
      app=$1
      exe=$2
      ws=$3
      move=$4

      if pgrep -x $exe > /dev/null; then
        notify-send "$app" "Already running"
        exit 0
      fi

      /run/current-system/sw/bin/$exe &
      pid=$!

      if [ "$move" = "move" ]; then
        move-window $app workspace $ws &
      fi

      wait $pid
    '')
  ];
}
