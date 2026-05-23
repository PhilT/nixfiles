{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "stop-machine" ''
      result=$(printf "Yes\nNo" | tofi -c /etc/config/tofi.ini --prompt-text "Sync to minoo? ")

      if [ -z "$result" ]; then
        exit 0
      fi

      if [ "$result" = "Yes" ]; then
        app-sync-minoo chromium to
      fi

      case $1 in
        shutdown) shutdown now ;;
        reboot) reboot ;;
      esac
    '')
  ];
}
