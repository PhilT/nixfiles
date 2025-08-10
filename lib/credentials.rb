require 'active_support/encrypted_file'
require 'yaml'
require_relative 'system'

CREDENTIALS_PATH = File.join(__dir__, "../config/credentials.yml.enc")
MASTER_KEY_PATH  = File.join(__dir__, "../config/master.key")
INITIAL_CONTENT  = <<~YAML
  ---
  wifi_home:
    username: Thompson
    password: password
  wifi_mobile:
    username: suuno
    password: password
YAML

class Credentials < Thor
  include System

  desc "edit", "Edit encrypted credentials. Generates a new key if none exists"
  def edit
    exit_with "EDITOR environment variable not set." unless ENV['EDITOR']

    generate_key unless File.exist?(CREDENTIALS_PATH)

    decrypted_content = encrypted_file.read
    Tempfile.create(["credentials", ".yml"]) do |f|
      f.write(decrypted_content)
      f.flush
      system("#{ENV['EDITOR']} #{f.path}")

      f.rewind
      updated_content = f.read

      begin
        YAML.safe_load(updated_content, aliases: true)
      rescue => e
        exit_with "YAML error: #{e.message}"
      end

      encrypted_file.write(updated_content)
      log "CREDENTIALS", "Updated"
    end
  end

  private

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