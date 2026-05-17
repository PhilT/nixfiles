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

  # Reference windows kept in the scratchpad. Toggle via $mod+<key>.
  scratchpadWindows = [
    { appId = "keymapp"; mark = "keymapp"; key = "q"; keepFocus = false; width = 981;  height = 581;  }
    { appId = "colemak"; mark = "colemak"; key = "g"; keepFocus = true;  width = 1962; height = 1527; }
  ];
}
