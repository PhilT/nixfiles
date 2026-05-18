{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "moxel" ''
      cd /data/code/matter && exec nix-shell --run ./target/dev-release/moxel
    '')
  ];
}
