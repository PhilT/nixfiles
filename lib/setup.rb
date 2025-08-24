require_relative "wallpaper"
require_relative "settings"

class Setup
  include System

  ALL_CHANNELS = %w[catppuccin nixos-hardware nixos]
  CATPPUCCIN_CHAN = "https://github.com/catppuccin/nix/archive/main.tar.gz"
  HARDWARE_CHAN = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"
  NIXOS_CHAN = "https://nixos.org/channels/nixos-unstable"
  HOME_DIR = "/home/nixos"

  attr_reader :options

  def initialize(machine, options = {}, root:, credentials:)
    @machine = machine
    @options = options
    @root = root
    @module = options[:module] || "minimal.nix"
    @settings = Settings.new
    @nixfiles_repo = @settings.nixfiles_repo
    @nixfiles_dir = File.join(@root, "data/code/nixfiles")
    @configuration_nix = File.join(@nixfiles_dir, "src/machines", @machine, @module, ".nix")
    @github_ssh_key = "#{HOME_DIR}/github_ssh_key"
    @ssh = Ssh.new(@machine, options, credentials)
  end

  def show_config
    log "CONF", "Show hardware configuration"
    run "nixos-generate-config --show-hardware-config", show: true
  end

  def github_ssh_key
    keys = @ssh.key_pair_for("github", "ed25519")
    File.write(@github_ssh_key, keys[:private])
    File.write("#{@github_ssh_key}.pub", keys[:public])
    File.chmod(600, @github_ssh_key)
  end

  def all_ssh_keys
    @ssh.generate_all_keys

    persisted_machine_dir = "/data/machine"
    persisted_machine_dir = ENV["HOME"] unless File.directory?(persisted_machine_dir)
    @ssh.write_keys_to "#{persisted_machine_dir}/ssh"
  end

  def wifi(use_network_manager: false)
    if connected? && !dry_run?
      state "NET", "Connected"
    else
      state "NET", "Disconnected. Establish WIFI connection"
      network = "wifi_#{options[:wifi]}"
      ssid, psk = all_credentials.dig(network).slice("ssid", "password")

      if use_network_manager
        sudo "nmcli device wifi connect #{ssid} password #{psk}"
      else
        sudo %(sh -c 'wpa_passphrase "#{ssid}" "#{psk}" > /etc/wpa_supplicant.conf')
        output = run "ls /sys/class/ieee80211/*/device/net/"
        sudo "wpa_supplicant -B -i#{output.strip} -c/etc/wpa_supplicant.conf"
      end
      wait_for_connection
    end
  end

  def add_channels
    channel_list = sudo("nix-channel --list", dryrun: false).split(/\n| /)
    if ALL_CHANNELS.all?{ channel_list.include?(it) }
      log "CHANNELS", "Up-to-date"
    else
      log "CHANNELS", "Updating"
      sudo "nix-channel --add #{CATPPUCCIN_CHAN} catppuccin"
      sudo "nix-channel --add #{HARDWARE_CHAN} nixos-hardware"
      sudo "nix-channel --add #{NIXOS_CHAN} nixos"
      sudo "nix-channel --update"
    end
  end

  def wallpaper
    Wallpaper.start(["download"])
  end

  def clone
    log "CLONE", "Cloning nixfiles repo"
    ssh_cmd = "GIT_SSH_COMMAND='ssh -i #{@github_ssh_key}'"
    sudo ssh_cmd, "git", "clone", @nixfiles_repo, @nixfiles_dir
  end

  def install
    log "INSTALL", "Installing NixOS"
    sudo "mkdir -p #{@root}/etc/nixos"
    sudo "ln -fs #{@configuration_nix} #{@root}/etc/nixos/configuration.nix"
    sudo "nixos-install", "--no-root-password"
    state "REBOOT", "Rebooting..."
    sudo "chown", "1000:users", File.join(@root, "data")
    sudo "chown", "-R", "1000:users", @nixfiles_dir
    sudo "umount", "-l", @root
    sudo "zpool", "export", "-a"
    reboot
  end

  private

  def dry_run?
    options[:dryrun]
  end

  def connected?
    return true if dry_run?

    !!run("ping -c 1 google.com > /dev/null 2>&1")
  end

  def wait_for_connection
    print "Waiting for connection..."
    while !connected? do
      sleep 1
      print "."
    end
    puts ""
    log "NET", "Connected"
  end
end