{ config, pkgs, ... }: {
  imports = [
    ./scripts/move-window.nix
  ];

  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-esr-140;
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1"; # Smooth scrolling
  environment.sessionVariables.MOZ_ENABLE_WAYLAND = "1"; # Wayland support (Should enable WebGL)

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
      app-sync firefox firefox-esr 6 $@
    '')

    # Example for syncing Firefox profile to minoo:
    # app-sync-minoo firefox to
    (writeShellScriptBin "app-sync-minoo" ''
      EXCLUDES="--exclude=cache2 --exclude=.lock --exclude=parent.lock --exclude=startupCache --exclude=crash_reports"

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

      if [ -f /data/home/$app/lock ]; then
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
        if [ "$app" = "firefox" ]; then
          move-window 'firefox title=(?!Monkeytype)' workspace $ws &

          # Move monkeytype to workspace 5
          move-window 'firefox title=Monkeytype' absolute position 3841 45 &
          sleep 1
          move-window 'firefox title=Monkeytype' window to workspace 5
        else
          move-window $app workspace $ws &
        fi
      fi

      wait $pid

      app-sync-minoo $app to
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