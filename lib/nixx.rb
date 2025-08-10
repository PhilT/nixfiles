require "thor"
require_relative "credentials"
require_relative "system"
require_relative "ssh"

CATPPUCCIN_CHAN = "https://github.com/catppuccin/nix/archive/main.tar.gz"
HARDWARE_CHAN = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz"

class Nixx < Thor
  include System
  include Ssh

  desc "build", "Rebuild NixOS"
  option :switch, type: :boolean, default: false, aliases: :s,
    desc: "Switch to the new machine config"
  option :boot, type: :boolean, default: false, aliases: :b,
    desc: "Switch to the new config on next boot"
  option :upgrade, type: :boolean, default: false, aliases: :u,
    desc: "Upgrade the channel and switch"
  option :clean, type: :boolean, default: false,
    desc: "Run nix-collect-garbage -d"
  option :machine, type: :string, default: nil, aliases: :m,
    desc: "Build a different machine (aramid/minoo/seedling/spruce)"
  option :module, type: :string, default: nil, aliases: :o,
    desc: "Pick a base module from machines/$machine/. Defaults to default.nix"
  option :trace, type: :boolean, default: false, aliases: :t,
    desc: "Show trace"
  option :dryrun, type: :boolean, default: false,
    desc: "Dry run - don't write any keys to disk"
  option :overwrite, type: :boolean, default: false,
    desc: "Overwrite existing keys"
  def build
    command = options["dryrun"] ? "dry-build" : "build"
    command = "switch" if options.slice(:switch, :upgrade, :clean).any?
    command = "boot" if options[:boot]
    etc_dir = ephemeral_os? ? "/data/etc" : "/etc"

    add_channels
    write_keys_to_ssh_dir(
      machine,
      dry_run: options[:dryrun],
      overwrite: options[:overwrite]
    )

    log command, machine
    sudo("nix-collect-garbage -d") if options[:clean]
    sudo("nix-channel --update") if upgrade

    make_public_keys_available do
      sudo("#{configuration_nix} nixos-rebuild #{command}#{trace} |& nom")
    end
  end

  desc "sha URL", "Fetch a SHA256 for the given package"
  def sha(url)
    # Might need to add --unpack if we're prefetching an archive
    run("nix-prefetch-url #{url}")
  end

  desc "option OPTION", "Output value of a config option e.g. persistedHomeDir"
  option :module, type: :string, default: nil, aliases: :o,
    desc: "Pick a base module from machines/$machine/. Defaults to default.nix"
  option :machine, type: :string, default: nil, aliases: :m,
    desc: "Build a different machine (aramid/minoo/seedling/spruce)"
  def option(option)
    run("#{configuration_nix} nixos-option #{option}")
  end

  desc "credentials", "Manage encrypted credentials"
  subcommand "credentials", Credentials

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

  def configuration_nix
    @configuration_nix ||=
      begin
        config = File.join(ROOT_DIR, "src/machines/#{machine}/#{modul}")
        "NIXOS_CONFIG=#{config}"
      end
  end

  def add_channels
    channel_list =
      sudo("nix-channel --list", return_output: true)
      .strip
      .gsub("\n", " ")
    if channel_list =~ /catppuccin.*nixos-hardware/
      log "CHANNELS", "Up-to-date"
    else
      log "CHANNELS", "Updating"
      sudo("nix-channel --add #{CATPPUCCIN_CHAN} catppuccin")
      sudo("nix-channel --add #{HARDWARE_CHAN} nixos-hardware")
      upgrade = true
    end
  end

  def trace
    options[:trace] ? " --show-trace" : ""
  end

  def ephemeral_os?
    %w[aramid seedling].include?(machine)
  end
end