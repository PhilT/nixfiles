{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Load Neovim with previous session setup
    (writeShellScriptBin "v" ''
      nvim -S Session.vim
    '')
  ];
}
