# Needed for some ZSA tools to work
# https://github.com/ungoogled-software/ungoogled-chromium/blob/master/docs/flags.md
{ config, pkgs, ... }: {
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

      (ungoogled-chromium.override {
        enableWideVine = true;
        commandLineArgs = [
          "--password-store=basic"
          "--no-first-run"
          "--no-default-browser-check"
          "--ozone-platform-hint=auto"
          "--user-data-dir=/data/home/chromium"
        ];
      })

      (writeShellScriptBin "quit-chromium" ''
        focused=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused) | .app_id')
        if echo "$focused" | grep -q chromium; then
          pkill chromium
        else
          swaymsg kill
        fi
      '')
    ];
  };
}
