{ config, pkgs, ... }: {
  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-esr-140;
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1"; # Smooth scrolling

  # Firefox normally lives in ~/.mozilla/firefox with a profiles.ini
  # which indicates where the profile is stored. We point this to
  # /data/home/firefox so it can be synced between machines.
  # homeDir is ~
  # persistedHomeDir is /data/home

  environment.etc."firefox/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${config.persistedHomeDir}/firefox
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2
  '';

  systemd.tmpfiles.rules = [
    "d ${config.homeDir}/.mozilla - ${config.username} users"
    "d ${config.homeDir}/.mozilla/firefox - ${config.username} users"
    "L+ ${config.homeDir}/.mozilla/firefox/profiles.ini - - - - /etc/firefox/profiles.ini"
  ];

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ff" ''
      app-sync Firefox firefox firefox-esr 7 $@
    '')

    (writeShellScriptBin "app-sync-minoo" ''
      EXCLUDES="--exclude=cache2 --exclude=.lock --exclude=parent.lock --exclude=startupCache --exclude=crash_reports"

      app=$1
      name=$2
      direction=$3
      remote_path=phil@minoo:/data/home/$app/
      local_path=/data/home/$app/

      if [ $direction = to ]; then
        to=$remote_path
        from=$local_path
      else
        to=$local_path
        from=$remote_path
      fi

      if [ -f /data/home/$app/lock ]; then
        notify-send -u critical "Lock file found, skipping sync"
      else
        id=$(notify-send -p -t 18000000 "$name profile sync" "Syncing $direction minoo...")
        rsync -a --delete $EXCLUDES $from $to
        notify-send -r $id -t 5000 "$name profile sync" "Complete"
      fi
    '')

    (writeShellScriptBin "app-sync" ''
      name=$1
      app=$2
      exe=$3
      ws=$4
      move=$5

      app-sync-minoo $app $name from

      /run/current-system/sw/bin/$exe &
      pid=$!

      if [ "$move" = "move" ]; then
        notify-send "Moving $name to $ws"
        # Move apps as quickly as possible but keep trying
        # for slower machines.
        for i in {1..4}; do
          sleep 1
          swaymsg "[app_id=$app] move workspace $ws"
        done
      fi

      wait $pid

      app-sync-minoo $app $name to
    '')
  ];

  programs.firefox.preferences = {
    "browser.tabs.inTitlebar" = 0;
    "browser.backspace_action" = 0;
    "browser.warnOnQuit" = false;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "apz.gtk.kinetic_scroll.enabled" = false;
  };

  # https://mozilla.github.io/policy-templates
  programs.firefox.policies = {
    DisableTelemetry = true;
    DefaultDownloadDirectory = "${config.dataDir}/downloads";
    DownloadDirectory = "${config.dataDir}/downloads";
    PromptForDownloadLocation = false;
    DisableAppUpdate = true;
    ManualAppUpdateOnly = true;
    DisplayBookmarksToolbar = "newtab";
    NoDefaultBookmarks = true;
    OfferToSaveLogins = false;
    OverrideFirstRunPage = "";
    PasswordManagerEnabled = false;
    DisableMasterPasswordCreation = true;
    EnableTrackingProtection = {
      Value = true;
      Locked = false;
      Cryptomining = true;
      Fingerprinting = true;
    };
    EncryptedMediaExtensions.enabled = false;
    FirefoxHome = {
      Search = false;
      TopSites = false;
      SponsoredTopSites = false;
      Highlights = false;
      Pocket = false;
      SponsoredPocket = false;
      Snippets = false;
      Locked = false;
    };
    Homepage.StartPage = "previous-session";
    Permissions = {
      Camera.Allow = [ "https://*.google.com" "https://*.microsoft.com" ];
      Microphone.Allow = [ "https://*.google.com" ];
      Location.Allow = [];
      Notifications.Allow = [];
      Autoplay.Allow = [];
    };
    PopupBlocking = {
      Allow = [];
      Default = false;
    };
    RequestedLocales = [ "en-GB" ];
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        installation_mode = "force_installed";
        install_url = "https://github.com/gorhill/uBlock/releases/download/1.62.0/uBlock0_1.62.0.firefox.signed.xpi";
      };
    };
    SearchEngines = {
      Add = [
        {
          Name = "Perplexity";
          URLTemplate = "https://www.perplexity.ai/search?q={searchTerms}";
          Method = "GET";
          IconURL = "https://www.perplexity.ai/favicon.ico";
        }
        {
          Name = "SearXNG";
          URLTemplate = "https://search.leptons.xyz/search?q={searchTerms}";
          Method = "GET";
          IconURL = "https://search.leptons.xyz/searxng/favicon.ico";
        }
      ];
      Default = "Perplexity";
    };
    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnboarding = true;
      MoreFromMozilla = false;
    };
  };
}