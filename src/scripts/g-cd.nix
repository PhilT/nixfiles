{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "g-cd" ''
      [ -d "$CODE/$PROJ" ] || git clone git@github.com:PhilT/$PROJ.git $CODE/$PROJ
      cd "$CODE/$PROJ"
    '')
  ];
}
