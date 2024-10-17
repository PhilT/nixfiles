{ config, lib, pkgs, ... }:
{
  imports = [
    ./audio.nix
    ./environment.nix
    ./fonts.nix
    ./git.nix
    ./mimetypes.nix
    ./neovim.nix
    ./programs.nix
    ./qemu.nix
    ./ranger.nix
    ./tmux.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings = {
      auto-optimise-store = true;

      # @wheel means all users in the wheel group
      trusted-users = [
        config.username
        "root"
        "@wheel"
      ];
    };
  };

  boot.initrd.systemd.enable = true;

  # Don't log boot up to screen, turn off warning about sgx
  boot.kernelParams = [ "quiet" "nosgx" ];

  console = {
    packages=[ pkgs.terminus_font ];
    font="${pkgs.terminus_font}/share/consolefonts/ter-i18b.psf.gz";
    useXkbConfig = true;
  };
  services.xserver.xkb.layout = "gb";

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git.enable = true;

  environment.enableAllTerminfo = true;
  environment.systemPackages = with pkgs; [
    htop
    wget
    which
  ];
}