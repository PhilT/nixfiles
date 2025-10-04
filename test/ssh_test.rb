require "minitest/autorun"

require_relative "../lib/ssh"

class SshTest < Minitest::Test
  OPTIONS = { log: false }.freeze
  MACHINES = %w[minoo aramid]
  def subject = @subject ||= Ssh.new("minoo", OPTIONS, mock_credentials)

  def private_key = @private_key ||= SecureRandom.hex(100)
  def public_key = @public_key ||= SecureRandom.hex(100)
  def new_private_key = @private_key ||= SecureRandom.hex(100)
  def new_public_key = @public_key ||= SecureRandom.hex(100)
  def new_keys = { private: new_private_key, public: new_public_key }
  def mock_credentials
    @mock_credentials ||=
      begin
        @mock_credentials = Minitest::Mock.new
        @mock_credentials.expect(:[], credentials[:ssh], [:ssh])
        @mock_credentials
      end
  end

  def credentials
    @credentials ||=
      {
        ssh: {
          local: {
            minoo: { ed25519: { public: public_key, private: private_key } },
            aramid: { ed25519: { public: public_key, private: private_key } },
            new_machine: { ed25519: nil }
          },
          other: {
            minoo: { ed25519: { public: public_key, private: private_key } }
          }
        }
      }
  end

  def new_credentials
    {
      ssh: {
        local: {
          minoo: { ed25519: { public: public_key, private: private_key } },
          aramid: { ed25519: { public: public_key, private: private_key } },
          new_machine: { ed25519: { public: new_public_key, private: new_private_key } }
        },
        other: {
          minoo: { ed25519: { public: public_key, private: private_key } }
        }
      }
    }
  end

  def setup
    @key_paths = ["/tmp/id_ed25519_minoo", "/tmp/id_ed25519_aramid"]
    @key_paths.each do |key_path|
      File.delete(key_path) if File.exist?(key_path)
      File.delete("#{key_path}.pub") if File.exist?("#{key_path}.pub")
    end
  end

  def test_generate_all_keys
    subject.stub(:generate_key_pair, new_keys) do
      mock_credentials.expect(:[]=, nil, [:ssh, new_credentials[:ssh]])
      mock_credentials.expect(:save, nil)
      subject.generate_all_keys
      assert_mock mock_credentials
    end
  end

  def test_write_keys_to
    Dir.mktmpdir do |dir|
      subject.write_keys_to(dir)
      assert_equal "#{private_key}\n", File.read("#{dir}/id_ed25519")
      assert_equal public_key, File.read("#{dir}/id_ed25519.pub")
      assert_equal "#{private_key}\n", File.read("#{dir}/id_ed25519_other")
      assert_equal public_key, File.read("#{dir}/id_ed25519_other.pub")
    end
  end

  def test_key_pair_for
    expected_keys = { public: public_key, private: private_key }

    assert_equal expected_keys, subject.key_pair_for("local")
    assert_nil subject.key_pair_for("local", "not-minoo")
  end

  def test_generate_key_pair
    paths, keys = nil

    SecureRandom.stub(:hex, "_test") do
      key_pair = subject.generate_key_pair

      assert key_pair[:private].start_with?("-----BEGIN OPENSSH PRIVATE KEY-----")
      assert key_pair[:public].start_with?("ssh-ed25519 ")
    end

    refute File.exist?("/tmp/id_ed25519_test")
    refute File.exist?("/tmp/id_ed25519_test.pub")
  end

  def test_with_public_keys
    exists = []
    subject.with_public_keys do
      @key_paths.each do |key_path|
        exists << File.exist?(key_path)
        exists << (File.exist?("#{key_path}.pub") && File.read("#{key_path}.pub"))
      end
    end

    assert_equal [false, public_key, false, public_key], exists
    assert @key_paths.none? { File.exist?(it) }
  end
end