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
      defaultSearchProviderSearchURL = "https://search.leptons.xyz/searxng/search?q={searchTerms}";
      homepageLocation = "https://www.startpage.com";
      extraOpts = {
        BrowserSignin = 0;
        SyncDisabled = true;
        PasswordManagerEnabled = false;
        SpellcheckEnabled = true;
        SpellcheckLanguage = [ "en-GB" ];
        BookmarkBarEnabled = true;
        RestoreOnStartup = 4; # 4 means open a list of URLs
        RestoreOnStartupURLs = [
          "https://configure.zsa.io/train/home"
          "https://configure.zsa.io/voyager/layouts/default/latest/0"
          "https://typ.ing"
        ];
      };
      initialPrefs = {
        "browser" = {
          "custom_chrome_frame" = false; # Ensure borders and gaps are removed
        };
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      (ungoogled-chromium.override {
        commandLineArgs = [
          "--password-store=basic"
          "--no-first-run"
          "--no-default-browser-check"
        ];
      })
    ];
  };
}