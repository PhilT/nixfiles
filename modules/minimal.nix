{ config, lib, pkgs, ... }: {
  imports = [
    ./base.nix
    ./options.nix
  ];

  system.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      timeout = 0; # Use SPACE to override
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # Enable systemd in initrd for better shutdown handling of encrypted devices
    initrd.systemd.enable = true;

    initrd.luks.devices = lib.mkIf config.luks.enable {
      root = {
        device = config.luks.device;
        # Tell systemd this device is managed by initrd and shouldn't be detached during shutdown
        # This fixes the 20-30s shutdown delay with systemd 257+
        # See: https://github.com/systemd/systemd/issues/14224
        crypttabExtraOpts = [ "x-initrd.attach" ];
      };
    };

    extraModulePackages = with config.boot.kernelPackages; [];
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

  # Pin to an older linux version not available in nixpkgs. Sometimes useful
  #boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_6_6.override {
  #  argsOverride = rec {
  #    src = pkgs.fetchurl {
  #          url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${version}.tar.xz";
  #          sha256 = "sha256-qwa7qIUeS2guiDT2+Q5W0y3PmNjGLNU3Z2EEz9dXqPI=";
  #    };
  #    # See: https://forum.manjaro.org/t/shutdown-problem-with-kernels-6-15-and-6-16/179384
  #    # Problems with kernel 6.17 and nvidia drivers
  #    version = "6.16.10";
  #    modDirVersion = "6.16.10";
  #  };
  #});

  programs.fish.enable = true;                # Fish! Shell
  programs.fish.package = pkgs.fish.override { usePython = false; };
  documentation.man.cache.enable = false;   # Stops painfully slow builds when using Fish
  networking.hostName = config.machine;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = lib.mkForce [];
  networking.networkmanager.wifi.backend = "iwd";

  # nmcli colours, themed to Catppuccin Macchiato. nmcli reads
  # terminal-colors.d(5); its default faint (^[[2m) rows are near-invisible.
  environment.etc."terminal-colors.d/nmcli.scheme".text = ''
    # Catppuccin Macchiato -- truecolor 38;2;R;G;B
    connection-activated       38;2;166;218;149
    connection-activating      38;2;238;212;159
    connection-disconnecting   38;2;237;135;150
    connection-external        38;2;198;160;246
    connection-invisible       38;2;147;154;183
    connection-deprecated      38;2;245;169;127
    connectivity-full          38;2;166;218;149
    connectivity-limited       38;2;238;212;159
    connectivity-none          38;2;237;135;150
    connectivity-portal        38;2;245;169;127
    connectivity-unknown       38;2;147;154;183
    device-activated           38;2;166;218;149
    device-activating          38;2;238;212;159
    device-disconnected        38;2;237;135;150
    device-external            38;2;198;160;246
    device-firmware-missing    38;2;245;169;127
    device-plugin-missing      38;2;245;169;127
    device-unavailable         38;2;147;154;183
    device-disabled            38;2;147;154;183
    manager-running            38;2;166;218;149
    manager-starting           38;2;238;212;159
    manager-stopped            38;2;237;135;150
    permission-auth            38;2;238;212;159
    permission-no              38;2;237;135;150
    permission-yes             38;2;166;218;149
    prompt                     38;2;138;173;244
    state-asleep               38;2;147;154;183
    state-connected-global     38;2;166;218;149
    state-connected-local      38;2;238;212;159
    state-connected-site       38;2;139;213;202
    state-connecting           38;2;238;212;159
    state-disconnected         38;2;237;135;150
    state-disconnecting        38;2;237;135;150
    wifi-signal-excellent      38;2;166;218;149
    wifi-signal-good           38;2;139;213;202
    wifi-signal-fair           38;2;238;212;159
    wifi-signal-poor           38;2;245;169;127
    wifi-signal-unknown        38;2;147;154;183
    wifi-deprecated            38;2;245;169;127
    disabled                   38;2;147;154;183
    enabled                    38;2;166;218;149
  '';

  # nmtui (and any other libnewt/whiptail TUI) themed to Catppuccin Macchiato.
  # newt only knows the 16 named ANSI colours, but kitty maps those to the
  # Macchiato palette, so e.g. "blue" renders as #8aadf4. Entry format is
  # key=fg,bg with NO internal spaces (newt splits on whitespace); defaults
  # are root=white,blue -- the grey-on-blue this replaces.
  environment.etc."newt/palette.macchiato".text = ''
    # Catppuccin Macchiato for libnewt / nmtui
    root=white,black
    roottext=lightgray,black
    border=blue,black
    window=white,black
    shadow=black,black
    title=blue,black
    button=black,blue
    actbutton=black,cyan
    compactbutton=lightgray,black
    checkbox=white,black
    actcheckbox=black,cyan
    entry=white,black
    disentry=gray,black
    label=lightgray,black
    listbox=white,black
    actlistbox=black,blue
    sellistbox=black,cyan
    actsellistbox=black,blue
    textbox=white,black
    acttextbox=black,blue
    helpline=lightgray,black
    emptyscale=white,gray
    fullscale=white,blue
  '';
  environment.variables.NEWT_COLORS_FILE = "/etc/newt/palette.macchiato";

  # Speed up shutdown - reduce NetworkManager stop timeout (normally takes <1s)
  systemd.services.NetworkManager.serviceConfig.TimeoutStopSec = "10s";
  users.groups.fuse = {}; # TODO: Confirm whether this is needed (in extraGroups as well)
  users.groups.plugdev = {}; # Needed for ZSA Voyager udev rules (common_gui.nix)
  users.users."${config.username}" = {
    isNormalUser = true;
    createHome = true;
    uid = 1000;
    description = config.fullname;
    hashedPassword = (builtins.readFile /tmp/hashed_password);
    extraGroups = [
      "audio"
      "docker"
      "plugdev"
      "fuse"
      "networkmanager"
      "users"
      "video"
      "wheel"
    ];
    shell = pkgs.fish;
  };
  users.mutableUsers = false;
  security.sudo.wheelNeedsPassword = false;

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [ "ntp.3eck.net" "nts1.adopo.net" "time.cloudflare.com" ];
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor    # Fancy output for nixos-rebuild

    keepassxc
  ];

  systemd.tmpfiles.rules = [
    "L+ ${config.homeDir}/.config/fish - - - - ${config.persistedHomeDir}/config/fish"
  ];
}