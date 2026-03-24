RSpec.describe KubeKrypt::CLI do
  let(:cli) { described_class.new }

  describe "#version" do
    it "prints the current version" do
      expect { cli.version }.to output("#{KubeKrypt::VERSION}\n").to_stdout
    end
  end

  describe "#encrypt" do
    let(:key_name) { "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key" }
    let(:file_path) { "/tmp/secret.yaml" }
    let(:yaml_content) { {"apiVersion" => "v1", "kind" => "Secret", "data" => {"token" => "abc"}}.to_yaml }
    let(:encrypted_yaml) { "encrypted_yaml_output" }

    before do
      allow(File).to receive(:read).with(file_path).and_return(yaml_content)
      cli.options = cli.options.merge(kms_key: key_name)
    end

    it "calls Encryptor and prints the result" do
      allow(KubeKrypt::Encryptor).to receive(:call).and_return(encrypted_yaml)
      expect { cli.encrypt(file_path) }.to output("#{encrypted_yaml}\n").to_stdout
    end

    it "prints an error and exits if file is already encrypted" do
      already_encrypted = {"apiVersion" => "v1", "kubekrypt" => {"kms_key" => key_name}}.to_yaml
      allow(File).to receive(:read).with(file_path).and_return(already_encrypted)
      expect { cli.encrypt(file_path) }.to output(/already encrypted/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not found" do
      allow(File).to receive(:read).with(file_path).and_raise(Errno::ENOENT)
      expect { cli.encrypt(file_path) }.to output(/file not found/).to_stderr.and raise_error(SystemExit)
    end
  end

  describe "#decrypt" do
    let(:key_name) { "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key" }
    let(:file_path) { "/tmp/secret.enc.yaml" }
    let(:yaml_content) do
      {
        "apiVersion" => "v1",
        "kind" => "Secret",
        "data" => {"token" => "enc:abc"},
        "kubekrypt" => {"kms_key" => key_name}
      }.to_yaml
    end
    let(:decrypted_yaml) { "decrypted_yaml_output" }

    before do
      allow(File).to receive(:read).with(file_path).and_return(yaml_content)
      cli.options = cli.options.merge(base64: false)
    end

    it "calls Decryptor and prints the result" do
      allow(KubeKrypt::Decryptor).to receive(:call).and_return(decrypted_yaml)
      expect { cli.decrypt(file_path) }.to output("#{decrypted_yaml}\n").to_stdout
    end

    it "prints an error and exits if file is not encrypted" do
      plain = {"apiVersion" => "v1", "data" => {"token" => "abc"}}.to_yaml
      allow(File).to receive(:read).with(file_path).and_return(plain)
      expect { cli.decrypt(file_path) }.to output(/not encrypted/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not found" do
      allow(File).to receive(:read).with(file_path).and_raise(Errno::ENOENT)
      expect { cli.decrypt(file_path) }.to output(/file not found/).to_stderr.and raise_error(SystemExit)
    end
  end
end
