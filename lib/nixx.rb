#!/usr/bin/env ruby

require 'thor'
require 'active_support/encrypted_file'
require 'yaml'

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
    command = "build"
    command = "switch" if options[:switch]
    command = "boot" if options[:boot]
    command = "upgrade" if options[:upgrade]
    @machine = options[:machine] || `hostname`.strip
    modul = options[:module] || "default.nix"
    configuration_nix = File.join(__dir__, "src/machines/#{@machine}/#{modul}")
    etc_dir = ephemeral_os? ? "/data/etc" : "/etc"

    system("NIXOS_CONFIG=#{configuration_nix} nixos-rebuild #{command} |& nom")
  end

  private

  def exec(cmd)

  end

  def ephemeral_os?
    %w[aramid seedling].include?(@machine)
  end

end