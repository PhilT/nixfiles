# Needed for some ZSA tools to work
# https://github.com/ungoogled-software/ungoogled-chromium/blob/master/docs/flags.md
{ config, pkgs, ... }: {
  imports = [
    ./scripts/move-window.nix
  ];

  programs = {
    chromium = {
      enable = true; # This just enables the policies. Package is added below.
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
      ];
      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://duckduckgo.com/?q={searchTerms}";
      homepageLocation = "https://claude.ai";
      extraOpts = {
        BrowserSignin = 0;
        SyncDisabled = true;
        PasswordManagerEnabled = false;
        SpellcheckEnabled = true;
        SpellcheckLanguage = [ "en-GB" ];
        BookmarkBarEnabled = true;
        RestoreOnStartup = 1; # 1 means restore the last session
        MetricsReportingEnabled = false;
        DownloadDirectory = "${config.dataDir}/downloads";
        DefaultGeolocationSetting = 2;
        DefaultNotificationsSetting = 2;
        VideoCaptureAllowedUrls = [ "https://*.google.com" "https://*.microsoft.com" ];
        AudioCaptureAllowedUrls = [ "https://*.google.com" ];
      };
      initialPrefs = {
        "browser" = {
          "custom_chrome_frame" = false; # Ensure borders and gaps are removed
        };
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.persistedHomeDir}/chromium - ${config.username} users -"
  ];

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode "https://duckduckgo.com/?q=$@" &'')

      (writeShellScriptBin "ch" ''
        app-sync chromium chromium 8 $@
      '')

      (writeShellScriptBin "app-sync-minoo" ''
        EXCLUDES="--exclude=Cache --exclude=Code\ Cache --exclude=GPUCache --exclude=SingletonLock"

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
          rsync -a --delete $EXCLUDES $from $to
          notify-send -r $id -t 5000 "$app profile sync" "Complete"
        fi
      '')

      (writeShellScriptBin "app-sync" ''
        app=$1
        exe=$2
        ws=$3
        move=$4

        app-sync-minoo $app from

        /run/current-system/sw/bin/$exe &
        pid=$!

        if [ "$move" = "move" ]; then
          move-window $app workspace $ws &
        fi

        wait $pid

        app-sync-minoo $app to
      '')

      (ungoogled-chromium.override {
        commandLineArgs = [
          "--password-store=basic"
          "--no-first-run"
          "--no-default-browser-check"
          "--ozone-platform=wayland"
          "--user-data-dir=/data/home/chromium"
        ];
      })
    ];
  };
}
