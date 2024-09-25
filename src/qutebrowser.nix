{ config, lib, pkgs, ... }:

let
  colors = import ./macchiato.nix lib;
in with colors; {
  environment.systemPackages = with pkgs; [
    qutebrowser
  ];

  environment.etc."qutebrowser/config.py" = {
    mode = "444";
    text = ''
      # https://github.com/catppuccin/qutebrowser
      import os
      from urllib.request import urlopen

      # load your autoconfig, use this, if the rest of your config is empty!
      config.load_autoconfig()

      if not os.path.exists(config.configdir / "theme.py"):
          theme = "https://raw.githubusercontent.com/catppuccin/qutebrowser/main/setup.py"
          with urlopen(theme) as themehtml:
              with open(config.configdir / "theme.py", "a") as file:
                  file.writelines(themehtml.read().decode("utf-8"))

      if os.path.exists(config.configdir / "theme.py"):
          import theme
          theme.setup(c, 'macchiato', True)
      # End of theme loader

      config.load_autoconfig(False)
      c.auto_save.session = True
      # c.colors.webpage.darkmode.enabled = True
      c.url.default_page = "https://search.leptons.xyz/searxng/search"
      c.url.searchengines = {
        "DEFAULT": "https://search.leptons.xyz/searxng/search?q={}",
        "package": "https://search.nixos.org/packages?channel=unstable&query={}",
        "option": "https://search.nixos.org/options?channel=unstable&query={}",
        "github": "https://github.com/search?q={}&type=repositories",
      }
      c.url.start_pages = ["https://search.leptons.xyz/searxng/search"]
      c.downloads.location.directory = "/data/downloads"
      c.editor.command = ["nvim", "-f", "{file}", "-c", "normal", "{line}G{column0}l"]
      c.tabs.padding = { "top": 10, "left": 5, "bottom": 10, "right": 5 }
      #c.colors.tabs.bar.bg = "${hex base}"
      #c.colors.tabs.odd.bg = "${hex surface0}"
      #c.colors.tabs.odd.fg = "${hex text}"
      #c.colors.tabs.even.bg = "${hex surface0}"
      #c.colors.tabs.even.fg = "${hex text}"
    '';
  };

  systemd.tmpfiles.rules = [
    "d ${config.xdgConfigHome} - phil users -"
    "d ${config.xdgConfigHome}/qutebrowser - phil users -"

    # Fix for cursors in Waybar/Firefox
    "L+ ${config.xdgConfigHome}/qutebrowser/config.py - - - - /etc/qutebrowser/config.py"
  ];
}