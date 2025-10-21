# Needed for some ZSA tools to work
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
        ManagedBookmarks = [
          {
            toplevel_name = "Me";
          }
          {
            name = "Keyboard Training";
            url = "https://configure.zsa.io/train/home";
          }
          {
            name = "Configurator";
            url = "https://configure.zsa.io/voyager/layouts/default/latest/0";
          }
        ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      ungoogled-chromium
    ];
  };
}