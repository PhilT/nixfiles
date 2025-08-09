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
  option :machine, type: :string, default: nil, aliases: :m,
    desc: "Build a different machine (aramid/minoo/seedling/spruce)"
  option :module, type: :string, default: nil, aliases: :o,
    desc: "Pick a base module from machines/$machine/. Defaults to default.nix"
  def build
    @machine = options[:machine] || `hostname`.strip
    @sudo = `whoami`.strip == "root" ? "" : "sudo " # When run from nixos-enter we don't need sudo

    command = "build"
    command = "switch" if options[:switch]
    command = "boot" if options[:boot]
    command = "upgrade" if options[:upgrade]
    modul = options[:module] || "default.nix"
    configuration_nix = File.join(ROOT_DIR, "src/machines/#{@machine}/#{modul}")
    etc_dir = ephemeral_os? ? "/data/etc" : "/etc"

    system("#{@sudo} NIXOS_CONFIG=#{configuration_nix} nixos-rebuild #{command} |& nom")
  end

  desc "credentials", "Manage encrypted credentials"
  subcommand "credentials", Credentials

  private

  def exec(cmd)

  end

  def ephemeral_os?
    %w[aramid seedling].include?(@machine)
  end

end