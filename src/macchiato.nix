lib:
rec {
  join = lst: lib.concatStringsSep ", " (lib.map (x: toString x) lst);
  rgb = lst: "rgb(${join lst})";
  rgba = rgb: a: "rgba(${join rgb}, ${toString a})";
  hex = lst: "#${lib.concatStrings (lib.map lib.toHexString lst)}";

  rosewater = [244 219 214]; #f4dbd6
  flamingo = [240 198 198];  #f0c6c6
  pink = [245 189 230];      #f5bde6
  mauve = [198 160 246];     #c6a0f6
  red = [237 135 150];       #ed8796
  maroon = [238 153 160];    #ee99a0
  peach = [245 169 127];     #f5a97f
  yellow = [238 212 159];    #eed49f
  green = [166 218 149];     #a6da95
  teal = [139 213 202];      #8bd5ca
  sky = [145 215 227];       #91d7e3
  sapphire = [125 196 228];  #7dc4e4
  blue = [138 173 244];      #8aadf4
  lavender = [183 189 248];  #b7bdf8
  text = [202 211 245];      #cad3f5
  subtext1 = [184 192 224];  #b8c0e0
  subtext0 = [165 173 203];  #a5adcb
  overlay2 = [147 154 183];  #939ab7
  overlay1 = [128 135 162];  #8087a2
  overlay0 = [110 115 141];  #6e738d
  surface2 = [91 96 120];    #5b6078
  surface1 = [73 77 100];    #494d64
  surface0 = [54 58 79];     #363a4f
  base = [36 39 58];         #24273a
  mantle = [30 32 48];       #1e2030
  crust = [24 25 38];        #181926
}