{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Prompt for a title and set it on the focused sway workspace, shown in
    # waybar as "N.title". Sway parses the leading number, so $mod+N switching
    # and `assign` rules keep working. An empty title clears it back to "N".
    (writeShellScriptBin "name-workspace" ''
      num=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .num')
      title=$(printf "" | tofi -c /etc/config/tofi.ini --require-match=false --prompt-text "Workspace title: ")
      if [ -n "$title" ]; then
        swaymsg "rename workspace to \"$num.$title\""
      else
        swaymsg "rename workspace to \"$num\""
      fi
    '')
  ];
}
