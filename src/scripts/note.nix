{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Start Neovim with todays date as filename
    (writeShellScriptBin "note" ''
      cd $NOTES/log && nvim $(date +%Y-%m-%d).md
    '')
  ];
}
