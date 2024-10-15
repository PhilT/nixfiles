{ config, lib, pkgs, ... }:
{
  imports = [
    ./environment.nix
    ./audio.nix
    ./fonts.nix
    ./mimetypes.nix

    ./dbgate.nix
    ./filemanager.nix
    ./firefox.nix
    ./git.nix
    ./keepmenu.nix
    ./kitty.nix
    ./neovim.nix
    ./programs.nix
    ./qemu.nix
    ./qutebrowser.nix
    ./thunderbird.nix
    ./tmux.nix
  ];

  # Fix nose not being supported by Python 3.12
  # TODO: Check if this is still needed
  nixpkgs.overlays = [
    (_: prev: {
        python312 = prev.python312.override { packageOverrides = _: pysuper: { nose = pysuper.pynose; }; };
    })
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
  # boot.kernel.sysctl."net.core.rmem_max" = 2500000; # FIXME: What's this for?

  console = {
    packages=[ pkgs.terminus_font ];
    font="${pkgs.terminus_font}/share/consolefonts/ter-i18b.psf.gz";
    useXkbConfig = true;
  };
  services.xserver.xkb.layout = "gb";

  users.mutableUsers = false;

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

  security.sudo.wheelNeedsPassword = false;
}