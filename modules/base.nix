# Imported by iso.nix and minimal.nix
{ config, pkgs, ... }: {
  environment = {
    systemPackages = with pkgs; [
      curl
      gcc
      git
      git-filter-repo
      gnumake
      htop
      lsof
      pkg-config
      wget
      which

      (callPackage ./nixx.nix {})
      (callPackage ./cratedocs-mcp.nix {})
    ];
  };
}
