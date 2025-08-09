require 'thor'
require_relative 'credentials'

ROOT_DIR = File.expand_path(File.join(__dir__, ".."))

class Nixx < Thor
  # Basic build functionality
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
  def build
    @machine = options[:machine] || `hostname`.strip
    @upgrade = true if options[:upgrade]

    command = "build"
    command = "switch" if options.slice(:switch, :upgrade, :clean).any?
    command = "boot" if options[:boot]
    modul = options[:module] || "default.nix"
    configuration_nix = File.join(ROOT_DIR, "src/machines/#{@machine}/#{modul}")
    etc_dir = ephemeral_os? ? "/data/etc" : "/etc"

    add_channels

    puts "[#{command.upcase}] #{@machine}"
    sudo("nix-collect-garbage -d") if options[:clean]
    sudo("nix-channel --update") if @upgrade
    sudo("NIXOS_CONFIG=#{configuration_nix} nixos-rebuild #{command}#{trace} |& nom")
  end

  desc "sha URL", "Fetch a SHA256 for the given package"
  def sha(url)
    # Might need to add --unpack if we're prefetching an archive
    run("nix-prefetch-url #{url}")
  end

  desc "credentials", "Manage encrypted credentials"
  subcommand "credentials", Credentials

  private

  def add_channels
    print "[CHANNELS] "
    channel_list = sudo("nix-channel --list", return_output: true).strip.gsub("\n", " ")
    if channel_list =~ /catppuccin.*nixos-hardware/
      puts "Up-to-date"
    else
      puts "Updating"
      sudo("nix-channel --add https://github.com/catppuccin/nix/archive/main.tar.gz catppuccin")
      sudo("nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware")
      @upgrade = true
    end
  end

  def sudo(cmd, return_output: false)
    @sudo ||= `whoami`.strip == "root" ? "" : "sudo " # When run from nixos-enter we don't need sudo
    run("#{@sudo}#{cmd}", return_output:)
  end

  def run(cmd, return_output: false)
    if return_output
      `#{cmd}`
    else
      system(cmd)
    end
  end

  def trace
    options[:trace] ? " --show-trace" : ""
  end

  def ephemeral_os?
    %w[aramid seedling].include?(@machine)
  end
end