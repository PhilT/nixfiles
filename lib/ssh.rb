require "pry"
require_relative "credentials"

module Ssh
  def write_keys_to_ssh_dir(this_machine, dry_run: false, overwrite: false)
    home_dir = ENV["HOME"]
    persisted_machine_dir = "/data/machine"
    persisted_machine_dir = ENV["HOME"] unless File.directory?(persisted_machine_dir)
    ssh_dir = "#{persisted_machine_dir}/ssh"
    if File.directory?(ssh_dir)
      log "SSH", "#{ssh_dir} folder exists"
    else
      log "SSH", "No SSH folder. Creating #{ssh_dir}"
      Dir.mkdir(ssh_dir)
      File.chmod(0700, ssh_dir)
    end

    Credentials.new.load["ssh"].each do |service, services|
      service = service == "local" ? "" : "_#{service}"

      services.each do |machine, key_types|
        next unless machine == this_machine || machine == "all"

        key_types.each do |key_type, keys|
          keypath = File.join(ssh_dir, "id_#{key_type}#{service}")
          keypath_pub = "#{keypath}.pub"
          if File.exist?(keypath_pub)
            existing_public_key = File.read(keypath_pub)
            if existing_public_key.split(" ")[1] == keys["public"].split(" ")[1]
              if overwrite
                log "SSH", "Overwriting #{keypath}"
              else
                log "SSH", "#{keypath} Matches existing key. Skipping"
                next
              end
            else
              if overwrite
                log "SSH", "#{keypath} does not match existing key. Overwriting"
              else
                log "SSH", "#{keypath} does not match existing key. " \
                  "Specify --overwrite to overwrite"
                next
              end
            end
          end

          if dry_run
            log "SSH", "Would write to #{keypath}"
            log "SSH", "Would write to #{keypath_pub}"
          else
            File.write(keypath, keys["private"])
            File.write(keypath_pub, keys["public"])
            File.chmod(0600, keypath)
            log "SSH", "#{keypath} and .pub written"
          end
        end
      end
    end
  end

  # To be used by the Nix configuration (src/ssh.nix)
  def write_public_keys_to_tmp
    Credentials.new.load.dig("ssh", "local").map do |machine, key_types|
      keys = key_types["ed25519"]

      if keys
        key_path = "/tmp/id_ed25519_#{machine}.pub"
        File.write(key_path, keys["public"])
        key_path
      else
        log "SSH", "No ed25519 keys for #{machine}. Skipping"
        nil
      end
    end.compact
  end

  def make_public_keys_available
    key_paths = write_public_keys_to_tmp
    yield
    key_paths.each { File.delete(it) }
  end
end