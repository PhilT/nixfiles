{ config, pkgs, ... }:

{
  imports = [
    ./bootstrap.nix
  ];

  # Enable the X11 windowing system
  services = {
    xserver = {
      enable = true;
      layout = "gb";
      libinput.enable = true; # Touchpad support
      displayManager = {
        lightdm.enable = false;
        startx.enable = true;
      };
      windowManager.dwm.enable = true;
      windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = builtins.fetchGit {
          url = "https://github.com/PhilT/dwm.git";
          ref = "main"; # Could move this to machine specific config to have diff configs
        };
      };
    };
  };

  # rtkit is optional but recommended
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Environment variables
  environment.sessionVariables = rec {
    CDPATH   = "${CODE_DIR}";
    CODE_DIR = "/home/phil/code";
    DOTNET_CLI_TELEMETRY_OPTOUT = "true";
    EDITOR = "$VISUAL";
    FZF_DEFAULT_COMMAND = "rg --files --no-ignore-vcs --hidden --ignore-file ~/.ignore";
    HISTCONTROL = "ignoreboth:erasedups";
    HISTFILESIZE = "";  # Unlimited history
    HISTSIZE = "";      # Unlimited history
    PROMPT_COMMAND = "history -a";
    VISUAL = "nvim";
  };

  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    dmenu
    feh
    ripgrep
    ungoogled-chromium
    unzip
    xscreensaver
    zip
  ];

}
