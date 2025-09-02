require_relative "credentials"

# Generates SSH keys and adds them to credentials file as well as
# ~/.ssh folder.
#
# Nomenclature:
# authorized_keys is what sshd accepts as incoming requests.
# known_hosts is what an ssh client knows about when connecting to
class Ssh
  include System

  def initialize(machine, options = {}, credentials = Credentials.new)
    @machine = machine
    @options = options
    @credentials = credentials
    @ssh_keys = credentials[:ssh]
  end

  # On machine setup, write its SSH keys from the credentials file to the
  # .ssh folder.
  def write_keys_to(ssh_dir)
    if File.directory?(ssh_dir)
      log "SSH", "#{ssh_dir} folder exists"
    else
      log "SSH", "No SSH folder. Creating #{ssh_dir}"
      mkdir(ssh_dir)
      chmod(0700, ssh_dir)
    end

    @ssh_keys.each do |service, machines|
      service_path = service == :local ? "" : "_#{service}"

      machines.each do |machine, key_types|
        next unless [@machine.to_sym, :all].include?(machine)

        key_types.each do |key_type, keys|
          keypath = File.join(ssh_dir, "id_#{key_type}#{service_path}")
          keypath_pub = "#{keypath}.pub"
          if File.exist?(keypath_pub)
            existing_public_key = File.read(keypath_pub)
            if existing_public_key.split(" ")[1] == keys[:public].split(" ")[1]
              if options[:overwrite]
                log "SSH", "Overwriting #{keypath}"
              else
                log "SSH", "#{keypath} Matches existing key. Skipping"
                next
              end
            else
              if options[:overwrite]
                log "SSH", "#{keypath} does not match existing key. Overwriting"
              else
                log "SSH", "#{keypath} does not match existing key. " \
                  "Specify --overwrite to overwrite"
                next
              end
            end
          elsif keys.dig(:public).nil?
            log "SSH", "ssh.#{service}.#{machine}.#{key_type} is not set in credentials file. Skipping"
            next
          end

          write_ssh_key(keypath, keys)
        end
      end
    end
  end

  # Generates a key for each machine, service and key type
  # unless one exists in the credentials file.
  def generate_all_keys
    dirty = false
    @ssh_keys.each do |service, machines|
      machines.each do |machine, key_types|
        key_types.each do |key_type, keys|
          if keys&.dig(:public)
            log "SSH", "#{key_type} key for #{service}/#{machine} exists"
          else
            log "SSH", "Generating #{key_type} key for #{service}/#{machine}"
            @ssh_keys[service][machine][key_type] = generate_key_pair
            dirty = true
          end
        end
      end
    end
    @credentials[:ssh] = @ssh_keys
    @credentials.save if dirty
  end

  # Fetch the public/private key pair for service, machine and type
  def key_pair_for(service, type = :ed25519)
    @ssh_keys.dig(service.to_sym, @machine.to_sym, type.to_sym)
  end

  # Generate SSH key with best encryption (ed25519 is the default anyway)
  # and 100 rounds (a bit slower but more secure).
  # Returns an array with the private and public key
  # Can be used to generate a new key to save to credentials file
  def generate_key_pair(keytype = "ed25519")
    private_key_path = File.join("/tmp", "id_#{keytype}#{SecureRandom.hex(10)}")
    public_key_path = "#{private_key_path}.pub"
    run("ssh-keygen", "-q", "-t", keytype, "-a", "100", "-f", private_key_path, "-N", '""')
    private_key = File.read(private_key_path)
    public_key = File.read(public_key_path)
    File.delete(private_key_path) if File.exist?(private_key_path)
    File.delete(public_key_path) if File.exist?(public_key_path)
    { public: public_key.split(" ")[0..1].join(" "), private: private_key }
  end

  # To be used by the Nix configuration (src/ssh.nix).
  # Temporarily makes the public keys available so the Nix configuration
  # can load them. Used by Nixx#build.
  def with_public_keys
    key_paths = write_public_keys_to_tmp
    yield
    key_paths.each { File.delete(it) if File.exist?(it) }
  end

  private

  def write_ssh_key(keypath, keys)
    keypath_pub = "#{keypath}.pub"
    log "SSH", "Writing to #{keypath} and #{keypath_pub}"

    write(keypath, "#{keys[:public]}\n")
    write(keypath_pub, keys[:public])
    chmod(0600, keypath)
  end

  def write_public_keys_to_tmp
    @ssh_keys[:local].map do |machine, key_types|
      keys = key_types[:ed25519]

      if keys
        key_path = "/tmp/id_ed25519_#{machine}.pub"
        File.write(key_path, keys[:public])
        key_path
      else
        log "SSH", "No ed25519 keys for #{machine}. Skipping"
        nil
      end
    end.compact
  end
end