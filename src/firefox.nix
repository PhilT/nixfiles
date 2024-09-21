{ config, pkgs, ... }:

{
  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-esr;
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1"; # Smooth scrolling

  programs.firefox.preferences = {
    "browser.tabs.inTitlebar" = 0;
    "browser.download.dir" = "/data/downloads";
    "browser.backspace_action" = 0;
    "browser.warnOnQuit" = false;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "apz.gtk.kinetic_scroll.enabled" = false;
  };

  # https://mozilla.github.io/policy-templates
  programs.firefox.policies = {
    DisableTelemetry = true;
    DefaultDownloadDirectory = "/data/downloads"; # FIXME: should really pass in $DATA
    DisableAppUpdate = true;
    ManualAppUpdateOnly = true;
    DisplayBookmarksToolbar = "newtab";
    NoDefaultBookmarks = true;
    OfferToSaveLogins = false;
    OverrideFirstRunPage = "";
    PasswordManagerEnabled = false;
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
        install_url = "https://github.com/gorhill/uBlock/releases/download/1.57.0/uBlock0_1.57.0.firefox.signed.xpi";
      };
    };
    SearchEngines = {
      Add = [
        {
          Name = "SearXNG";
          URLTemplate = "https://search.leptons.xyz/searxng/search?q={searchTerms}";
          Method = "GET";
          IconURL = "https://search.leptons.xyz/searxng/favicon.ico";
        }
      ];
      Default = "SearXNG";
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