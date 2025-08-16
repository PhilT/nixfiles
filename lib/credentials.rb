require "thor"
require "active_support/encrypted_file"
require "active_support/core_ext/hash/keys"
require "yaml"
require_relative "system"

INITIAL_CONTENT  = <<~YAML
  ---
  disks:
    encryption_password: PASSWORD
  wifi_home:
    ssid: SSID
    password: PASSWORD
YAML

class Credentials < Thor
  include System

  CREDENTIALS_PATH = File.join(ROOT_DIR, "config/credentials.yml.enc")
  MASTER_KEY_PATH  = File.join(ROOT_DIR, "config/master.key")

  desc "edit", "Edit encrypted credentials. Generates a new key if none exists"
  def edit
    exit_with "EDITOR environment variable not set." unless ENV["EDITOR"]

    generate_key unless File.exist?(CREDENTIALS_PATH)

    decrypted_content = encrypted_file.read
    Tempfile.create(["credentials", ".yml"]) do |f|
      f.write(decrypted_content)
      f.flush
      system("#{ENV["EDITOR"]} #{f.path}")

      f.rewind
      updated_content = f.read

      begin
        load_yaml(updated_content)
      rescue => e
        exit_with "YAML error: #{e.message}"
      end

      encrypted_file.write(updated_content)
      log "CREDS", "Updated"
    end
  end

  desc "read", "Read & output encrypted credentials from credentials.yml.enc"
  def read
    puts encrypted_file.read
  end

  no_commands do
    def credentials
      @credentials ||= load_yaml(encrypted_file.read)
    end

    def save
      encrypted_file.write(credentials.deep_stringify_keys.to_yaml)
    end

    delegate :[], :[]=, :dig, to: :credentials
  end

  private

  def load_yaml(from)
    YAML.safe_load(from, aliases: true, symbolize_names: true)
  end

  def generate_key
    File.write(MASTER_KEY_PATH, ActiveSupport::EncryptedFile.generate_key)
    encrypted_file.write(INITIAL_CONTENT)
  end

  def encrypted_file
    @encrypted_file ||= ActiveSupport::EncryptedFile.new(
      content_path: CREDENTIALS_PATH,
      key_path: MASTER_KEY_PATH,
      env_key: "NIXX_MASTER_KEY",
      raise_if_missing_key: true
    )
  end
end