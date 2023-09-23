{ config, pkgs, ... }:

# TODO: Get rid of Neomutt and rename
{
  programs.bash.interactiveShellInit = ''
    source ${../dotfiles/himalaya_completion}
  '';

  environment = {
    systemPackages = with pkgs; [
      neomutt
      urlscan       # View URLs in Emails (kind of important)
      links2        # For rendering HTML inline
      runningx      # Check if X is running so a browser can be started to view pages

      himalaya

      (writeShellScriptBin "emptymail" ''
        echo "Getting size of Trash folder..."
        emails=$(himalaya list -f Trash -s 10000 | sed '2 d')
        ids=$(echo "$emails" | sed -E 's/([0-9]+).*/\1/')
        echo "Deleting..."
        for i in $ids; do
          himalaya delete -f Trash $i > /dev/null
        done
        echo "Done."
      '')
    ];

    etc = {
      "himalaya.toml".source = ../dotfiles/himalaya.toml;
      "mailcap".source = ../dotfiles/mailcap;
      "xdg/neomutt/neomuttrc".source = ../dotfiles/neomuttrc;
      "xdg/neomutt/secrets.muttrc".source = ../secrets/secrets.muttrc;
      "xdg/neomutt/dracula.muttrc".source = ../dotfiles/dracula.muttrc;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/himalaya - phil users"
    "L+ ${config.xorg.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya.toml"
  ];
}
