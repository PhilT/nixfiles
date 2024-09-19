{ config, pkgs, ... }:

{
  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
        "paoafodbgcjnmijjepmpgnlhnogaahme" # Material Dark theme
      ];
      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://search.leptons.xyz/searxng/search?q={searchTerms}";
      homepageLocation = "https://www.startpage.com";
      extraOpts = {
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
        "SpellcheckEnabled" = true;
        "SpellcheckLanguage" = [ "en-GB" ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      chromium
    ];
  };
}