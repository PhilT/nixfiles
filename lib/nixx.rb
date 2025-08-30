require "thor"
require_relative "credentials"
require_relative "wallpaper"
require_relative "system"
require_relative "ssh"
require_relative "zfs"
require_relative "disks"
require_relative "setup"
require_relative "iso"
require_relative "usb"

class Nixx < Thor
  include System
  include Zfs
  include Iso

  class_option :dryrun, type: :boolean, default: false,
    desc: "Dry run - don't write any SSH keys to disk and run dry-build"
  class_option :module, type: :string, default: nil, aliases: :o,
    desc: "Pick a base module from machines/$machine/. Defaults to default.nix, for build & minimal.nix for setup"
  class_option :machine, type: :string, default: nil, aliases: :m,
    desc: "Build a different machine (aramid/minoo/seedling/spruce)"
  class_option :wifi, type: :string, default: "home",
    desc: "WIFI network to connect to. home/mobile"

  desc "iso", "Build a NixOS ISO"
  def iso
    Ssh.new(nil, options).with_public_keys do
      writeIso ROOT_DIR
    end
  end

  desc "usb DEVICE", "Build a NixOS USB image. DEVICE = device name e.g. sda"
  def usb(device = nil)
    exit_with "No device specified. Usage: nixx usb DEVICE" unless device

    Usb.write(device)
  end

  desc "keys", "Generate and add SSH keys to credentials file. View them with `nixx credentials show`"
  def keys
    Ssh.new(nil, options).generate_all_keys
  end

  desc "setup", "Setup a new NixOS machine"
  option :show, type: :boolean, default: false,
    desc: "Show hardware configuration"
  option :install_only, type: :boolean, default: false,
    desc: "Install NixOS without formatting"
  def setup
    root = "/mnt/"
    credentials = Credentials.new
    disks = Disks.new(machine, wipe: true, root:, credentials:, options:)
    setup = Setup.new(machine, options, root:, credentials:)

    if options[:show]
      setup.show_config
    elsif options[:install_only]
      setup.github_ssh_key
      setup.install
    else
      setup.github_ssh_key
      setup.wifi
      disks.partition
      setup.clone
      setup.add_channels
      setup.wallpaper
      setup.install
    end
  end

  desc "build", "Rebuild NixOS"
  option :switch, type: :boolean, default: false, aliases: :s,
    desc: "Switch to the new machine config"
  option :boot, type: :boolean, default: false, aliases: :b,
    desc: "Switch to the new config on next boot"
  option :upgrade, type: :boolean, default: false, aliases: :u,
    desc: "Upgrade the channel and switch"
  option :clean, type: :boolean, default: false,
    desc: "Run nix-collect-garbage -d"
  option :trace, type: :boolean, default: false, aliases: :t,
    desc: "Show trace"
  option :overwrite, type: :boolean, default: false,
    desc: "Overwrite existing keys"
  def build
    command = options[:dryrun] ? "dry-build" : "build"
    command = "switch" if options.slice(:switch, :upgrade, :clean).any?
    command = "boot" if options[:boot]
    etc_dir = ephemeral_os? ? "/data/etc" : "/etc"
    root = "/"
    credentials = Credentials.new
    disks = Disks.new(machine, wipe: false, root:, credentials:, options:)
    setup = Setup.new(machine, options, root:, credentials:)
    ssh = Ssh.new(machine, options, credentials)

    setup.add_channels
    setup.all_ssh_keys # Writes any missing keys to the credentials file and to SSH dir
    setup.wifi use_network_manager: true

    switch_to_key_based_encryption if disks.more_than_one?

    log command, machine
    sudo("nix-collect-garbage -d") if options[:clean]
    sudo("nix-channel --update") if upgrade

    ssh.with_public_keys do
      sudo(
        "#{configuration_nix} nixos-rebuild #{command}#{trace} |& nom",
        use_system: true
      )
    end
  end

  desc "sha URL", "Fetch a SHA256 for the given package"
  def sha(url)
    # Might need to add --unpack if we're prefetching an archive
    run("nix-prefetch-url #{url}")
  end

  desc "option OPTION", "Output value of a config option e.g. persistedHomeDir"
  def option(option)
    run("#{configuration_nix} nixos-option #{option}")
  end

  desc "diff", "Diff changes between latest & prev upgrade"
  def diff
    run "nvd diff $(ls -d1v /nix/var/nix/profiles/system-*-link|tail -n 2)", show: true
  end

  desc "datasets", "Create any missing datasets and mount them"
  def datasets
    credentials = Credentials.new
    disks = Disks.new(machine, wipe: false, root: "/", credentials:, options:)
    disks.partition
  end

  desc "credentials", "Manage encrypted credentials"
  subcommand "credentials", Credentials

  desc "wallpaper", "Download wallpaper from Wallhaven"
  subcommand "wallpaper", Wallpaper

  private

  def upgrade
    @upgrade ||= true if options[:upgrade]
  end

  def machine
    @machine ||= options[:machine] || `hostname`.strip
  end

  def modul
    @modul ||= options[:module] || "default.nix"
  end

  def overwrite
    @overwrite ||= options[:overwrite]
  end

  def trace
    options[:trace] ? " --show-trace" : ""
  end

  def configuration_nix
    @configuration_nix ||=
      begin
        config = File.join(ROOT_DIR, "src/machines/#{machine}/#{modul}")
        "NIXOS_CONFIG=#{config}"
      end
  end

  def ephemeral_os?
    %w[aramid seedling].include?(machine)
  end
end