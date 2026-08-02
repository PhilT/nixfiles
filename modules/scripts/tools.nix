{ lib, pkgs, ... }:
let
  # The reminder list `tools` prints. Maintained by hand: when adding a
  # script, add a line here. Descriptions should fit one terminal line
  # alongside the 24-char name column.
  groups = [
    {
      title = "dev";
      tools = [
        { n = "nixx"; d = "build/switch NixOS, setup, credentials, generation diff"; }
        { n = "g-dirty"; d = "list $CODE repos with uncommitted changes (-b, -s)"; }
        { n = "g-cd"; d = "cd to a $CODE repo, cloning from GitHub if missing"; }
        { n = "v"; d = "nvim, restoring Session.vim"; }
        { n = "note"; d = "nvim on today's dated note in $NOTES/log"; }
        { n = "watcher"; d = "rerun a command when watched paths change"; }
        { n = "moxel"; d = "run the moxel dev build from /data/code/matter"; }
        { n = "resetperms"; d = "reset perms under cwd: dirs 755, files 644"; }
        { n = "qemu-system-x86_64-uefi"; d = "qemu with OVMF UEFI firmware"; }
      ];
    }
    {
      title = "mail";
      tools = [
        { n = "mail-sync"; d = "one mbsync + notmuch cycle (same as the timer)"; }
        { n = "mail-triage"; d = "triage unactioned INBOX mail one at a time"; }
        { n = "mail-archive"; d = "file message(s) into Archive/<year> and sync"; }
        { n = "mail-expunge-old"; d = "manual purge of >5y-old mail from IMAP (--dry-run)"; }
        { n = "mail-dump"; d = "debug: dump one message's html/markdown to /tmp"; }
        { n = "mail-find"; d = "debug: find INBOX message containing a substring"; }
        { n = "mail-thread-analyse"; d = "debug: quoted-block stats across notmuch threads"; }
        { n = "sync_minoo_mail"; d = "unison cold-archive mail backup with minoo"; }
      ];
    }
    {
      title = "media";
      tools = [
        { n = "de-acsm"; d = "decrypt Kobo ACSM epub, add to calibre, push to Boox"; }
        { n = "record"; d = "record a screen region to /data/videos/screens"; }
        { n = "get-music"; d = "download audio as mp3 (yt-dlp)"; }
        { n = "spectrum"; d = "terminal music player with spectrum analyser"; }
      ];
    }
    {
      title = "desktop";
      tools = [
        { n = "start-apps"; d = "session start: profile sync, launch and place apps"; }
        { n = "stop-machine"; d = "profile sync to minoo, then shutdown or reboot"; k = "Super+Ctrl+backspace, +Shift reboot"; }
        { n = "light"; d = "monitor brightness: bright/dim/up/down/off"; k = "brightness keys"; }
        { n = "kp"; d = "keepmenu password picker"; k = "Super+o"; }
        { n = "s"; d = "duckduckgo search in chromium"; }
        { n = "ch"; d = "chromium with profile sync, workspace 8"; }
        { n = "quit-chromium"; d = "close focused window, or kill chromium if focused"; k = "Ctrl+q"; }
        { n = "kitty-themes"; d = "preview kitty themes, or dump one to dotfiles"; }
      ];
    }
    {
      title = "sway";
      tools = [
        { n = "move-window"; d = "retry-move an app_id to a workspace/position"; }
        { n = "name-workspace"; d = "prompt for a title on the focused workspace"; k = "Super+t"; }
        { n = "scratchpad-toggle"; d = "show/hide a marked window on the idle output"; k = "Super+q keymapp, Super+g colemak"; }
        { n = "swap-workspaces"; d = "toggle workspaces 1-5/6-10 between outputs"; k = "Super+Shift+x"; }
        { n = "swap-workspace-contents"; d = "swap windows between the two visible workspaces"; k = "Super+x"; }
        { n = "restore-workspaces"; d = "reassign all workspaces to their outputs"; }
      ];
    }
    {
      title = "misc";
      tools = [
        { n = "app-sync-minoo"; d = "rsync an app profile to/from minoo"; }
        { n = "mergepasswords"; d = "merge KeePass conflict copies into HomeDatabase"; }
        { n = "payslips"; d = "extract and file a payslip zip by tax month"; }
        { n = "ranger-adb"; d = "browse the phone over adb in ranger"; }
        { n = "mxw"; d = "configure Glorious Model O mouse (USB only)"; }
        { n = "bt-sync-windows"; d = "copy Windows BT pairing keys into BlueZ (dual boot)"; }
        { n = "vk-fur"; d = "furmark vulkan stress test"; }
      ];
    }
  ];

  toolLine = t:
    if t ? k then ''
      printf '  %s%-24s%s%s %s(%s)%s\n' "$name_c" ${lib.escapeShellArg t.n} "$reset_c" ${lib.escapeShellArg t.d} "$key_c" ${lib.escapeShellArg t.k} "$reset_c"
    '' else ''
      printf '  %s%-24s%s%s\n' "$name_c" ${lib.escapeShellArg t.n} "$reset_c" ${lib.escapeShellArg t.d}
    '';
  groupBlock = g: ''
    printf '%s%s%s\n' "$group_c" ${lib.escapeShellArg g.title} "$reset_c"
  '' + lib.concatMapStrings toolLine g.tools + ''
    printf '\n'
  '';

  toolsBin = pkgs.writeShellApplication {
    name = "tools";
    # Descriptions are literal strings; $CODE in one of them trips SC2016.
    excludeShellChecks = [ "SC2016" ];
    text = ''
      group_c=$'\033[1;36m'
      name_c=$'\033[32m'
      key_c=$'\033[33m'
      reset_c=$'\033[0m'
    '' + lib.concatMapStrings groupBlock groups;
  };
in {
  environment.systemPackages = [ toolsBin ];

  # Greeting only in kitty windows: TTYs and non-kitty terminals stay quiet.
  # Defined as a function so it wins over the empty $fish_greeting variable
  # set in the persisted user config.fish.
  programs.fish.interactiveShellInit = ''
    function fish_greeting
      if test "$TERM" = xterm-kitty
        tools
      end
    end
  '';
}
