{
  outputs = {
    primary = "DP-2";     # spruce left monitor
    secondary = "DP-3";   # seedling right monitor
    fallback = "eDP-1";   # laptop display
  };

  # workspace number -> output key
  assignments = {
    "1"  = "secondary";  "2"  = "secondary";  "3"  = "secondary";
    "4"  = "secondary";  "5"  = "secondary";
    "6"  = "primary";    "7"  = "primary";     "8"  = "primary";
    "9"  = "primary";    "10" = "primary";
  };

  # Sticky floating windows positioned in the left gap on primary output
  floatingWindows = [
    { appId = "keymapp"; width = 981; height = 581;  x = 1; y = 45;  }
    { appId = "colemak"; width = 981; height = 1527; x = 1; y = 630; }
  ];

  # Non-sticky floating windows that need size restoration after output changes
  restoreWindows = [
    { appId = "firefox"; title = "Monkeytype"; width = 2539; height = 2110; }
  ];

  # Gap size on primary-output workspaces to make room for floating windows
  leftGap = 982;
}
