{ config, pkgs, ... }: {
  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-esr-140;
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1"; # Smooth scrolling

  environment.etc."firefox/profiles.ini".text = ''
    [Profile0]
    Name=default
    IsRelative=0
    Path=${config.persistedMachineDir}/firefox
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
      app-sync Firefox firefox firefox-esr $@
    '')

    (writeShellScriptBin "app-sync" ''
      name=$1
      app=$2
      exe=$3
      move=$4

      id=$(notify-send -p -t 18000000 "$name profile sync" "Server -> Local")
      rsync -a --delete phil@minoo:/data/home/$app/ ${config.persistedMachineDir}/$app/
      notify-send -r $id -t 5000 "$name profile sync" "Complete (Server -> Local)"

      /run/current-system/sw/bin/$exe &
      pid=$!

      if [ "$move" = "move" ]; then
        sleep 2
        swaymsg "[app_id=$app] move workspace 7"
      fi

      wait $pid

      id=$(notify-send -p -t 18000000 "$name profile sync" "Local -> Server")
      rsync -a --delete ${config.persistedMachineDir}/$app/ phil@minoo:/data/home/$app/
      notify-send -r $id -t 5000 "$name profile sync" "Complete (Local -> Server)"
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
      Camera.Allow = [ "https://*.google.com" ];
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