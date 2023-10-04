{ config, pkgs, ... }:

{
  programs.bash.interactiveShellInit = ''
    source ${../dotfiles/himalaya_completion}
  '';

  environment = {
    systemPackages = with pkgs; [
      himalaya

      (writeShellScriptBin "mail-empty" ''
        echo "Getting size of Trash folder..."
        emails=$(himalaya list -f Trash -s 10000 | sed '2 d')
        ids=$(echo "$emails" | sed -E 's/([0-9]+).*/\1/')
        echo "Deleting..."
        for i in $ids; do
          himalaya delete -f Trash $i > /dev/null
        done
        echo "Done."
      '')

      (writeShellScriptBin "mail-subject-with" ''
        if [ -z "$1" ]; then
          echo "Returns IDs contain <text> in the subject"
          echo "Usage:"
          echo "  $0 text"
          exit 1
        fi

        himalaya search SUBJECT $1 | sed 1,2d  | sed -E 's/([0-9]+) .*$/\1/'
      '')

      (writeShellScriptBin "mail-del" ''
        # e.g. mail-subject-with sometext | $0
        xargs -I{} himalaya delete {}
      '')

      (writeShellScriptBin "mail-read" ''
        sed -E 's/([0-9]+) .*$/\1/' | xargs -I{} himalaya read {}
      '')
    ];

    etc = {
      "himalaya.toml".source = ../dotfiles/himalaya.toml;
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.xorg.xdgConfigHome}/himalaya - phil users"
    "L+ ${config.xorg.xdgConfigHome}/himalaya/config.toml - - - - /etc/himalaya.toml"
  ];
}
