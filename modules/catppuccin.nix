lib:
rec {
  join = lst: lib.concatStringsSep ", " (lib.map (x: toString x) lst);
  rgb = lst: "rgb(${join lst})";
  rgba = rgb: a: "rgba(${join rgb}, ${toString a})";
  hex = lst: "#${lib.concatStrings (lib.map lib.toHexString lst)}";

  rosewater = [245 224 220]; #f5e0dc
  flamingo = [242 205 205];  #f2cdcd
  pink = [245 194 231];      #f5c2e7
  mauve = [203 166 247];     #cba6f7
  red = [243 139 168];       #f38ba8
  maroon = [235 160 172];    #eba0ac
  peach = [250 179 135];     #fab387
  yellow = [249 226 175];    #f9e2af
  green = [166 227 161];     #a6e3a1
  teal = [148 226 213];      #94e2d5
  sky = [137 220 235];       #89dceb
  sapphire = [116 199 236];  #74c7ec
  blue = [137 180 250];      #89b4fa
  lavender = [180 190 254];  #b4befe
  text = [205 214 244];      #cdd6f4
  subtext1 = [186 194 222];  #bac2de
  subtext0 = [166 173 200];  #a6adc8
  overlay2 = [147 153 178];  #9399b2
  overlay1 = [127 132 156];  #7f849c
  overlay0 = [108 112 134];  #6c7086
  surface2 = [88 91 112];    #585b70
  surface1 = [69 71 90];     #45475a
  surface0 = [49 50 68];     #313244
  base = [30 30 46];         #1e1e2e
  mantle = [24 24 37];       #181825
  crust = [17 17 27];        #11111b
}