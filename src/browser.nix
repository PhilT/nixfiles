{ config, pkgs, ... }:

{
  programs = {
    chromium = {
      enable = true;
      extensions = [
        "cgbcahbpdhpcegmbfconppldiemgcoii" # ublock origin
        "cdkhedhmncjnpabolpjceohohlefegak" # Startpage privacy protection
        "paoafodbgcjnmijjepmpgnlhnogaahme" # Material Dark theme
      ];
      defaultSearchProviderEnabled = true;
      defaultSearchProviderSearchURL = "https://www.startpage.com/sp/search?query={searchTerms}&cat=web&pl=chrome";
      homepageLocation = "https://www.startpage.com";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      (writeShellScriptBin "s" ''chromium --force-dark-mode https://www.startpage.com/sp/search?query="$@" &'')

      chromium
    ];
  };
}
