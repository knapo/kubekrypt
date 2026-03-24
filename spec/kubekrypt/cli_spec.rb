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
    let(:content) { {"apiVersion" => "v1", "kind" => "Secret", "data" => {"token" => "abc"}} }
    let(:encrypted_yaml) { "encrypted_yaml_output" }

    before do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return(content)
      cli.options = cli.options.merge(kms_key: key_name, in_place: false)
    end

    it "calls Encryptor and prints the result" do
      allow(KubeKrypt::Encryptor).to receive(:call).and_return(encrypted_yaml)
      expect { cli.encrypt(file_path) }.to output("#{encrypted_yaml}\n").to_stdout
    end

    context "with --in-place" do
      before { cli.options = cli.options.merge(in_place: true) }

      it "writes the result back to the file" do
        allow(KubeKrypt::Encryptor).to receive(:call).and_return(encrypted_yaml)
        expect(File).to receive(:write).with(file_path, encrypted_yaml)
        cli.encrypt(file_path)
      end
    end

    it "prints an error and exits if file is already encrypted" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return(content.merge("kubekrypt" => {"kms_key" => key_name}))
      expect { cli.encrypt(file_path) }.to output(/already encrypted/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not found" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_raise(Errno::ENOENT)
      expect { cli.encrypt(file_path) }.to output(/file not found/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if YAML is invalid" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_raise(Psych::Exception, "mapping values are not allowed here")
      expect { cli.encrypt(file_path) }.to output(/not valid YAML/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not a Secret" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return("apiVersion" => "v1", "kind" => "ConfigMap")
      expect { cli.encrypt(file_path) }.to output(/not a Kubernetes Secret/).to_stderr.and raise_error(SystemExit)
    end

    context "with a directory" do
      let(:dir) { "/tmp/secrets" }
      let(:file1) { "/tmp/secrets/a.yaml" }
      let(:file2) { "/tmp/secrets/b.yml" }

      before do
        allow(File).to receive(:directory?).with(dir).and_return(true)
        allow(Dir).to receive(:glob).and_return([file1, file2])
        allow(YAML).to receive(:safe_load_file).with(file1).and_return(content)
        allow(YAML).to receive(:safe_load_file).with(file2).and_return(content)
        allow(KubeKrypt::Encryptor).to receive(:call).and_return(encrypted_yaml)
      end

      it "processes all YAML files in the directory" do
        expect(KubeKrypt::Encryptor).to receive(:call).twice
        expect { cli.encrypt(dir) }.to output.to_stdout
      end
    end
  end

  describe "#decrypt" do
    let(:key_name) { "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key" }
    let(:file_path) { "/tmp/secret.enc.yaml" }
    let(:content) do
      {
        "apiVersion" => "v1",
        "kind" => "Secret",
        "data" => {"token" => "enc:abc"},
        "kubekrypt" => {"kms_key" => key_name}
      }
    end
    let(:decrypted_yaml) { "decrypted_yaml_output" }

    before do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return(content)
      cli.options = cli.options.merge(base64: false, in_place: false)
    end

    it "calls Decryptor and prints the result" do
      allow(KubeKrypt::Decryptor).to receive(:call).and_return(decrypted_yaml)
      expect { cli.decrypt(file_path) }.to output("#{decrypted_yaml}\n").to_stdout
    end

    context "with --in-place" do
      before { cli.options = cli.options.merge(in_place: true) }

      it "writes the result back to the file" do
        allow(KubeKrypt::Decryptor).to receive(:call).and_return(decrypted_yaml)
        expect(File).to receive(:write).with(file_path, decrypted_yaml)
        cli.decrypt(file_path)
      end
    end

    it "prints an error and exits if file is not encrypted" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return("apiVersion" => "v1", "kind" => "Secret", "data" => {"token" => "abc"})
      expect { cli.decrypt(file_path) }.to output(/not encrypted/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not found" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_raise(Errno::ENOENT)
      expect { cli.decrypt(file_path) }.to output(/file not found/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if YAML is invalid" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_raise(Psych::Exception, "mapping values are not allowed here")
      expect { cli.decrypt(file_path) }.to output(/not valid YAML/).to_stderr.and raise_error(SystemExit)
    end

    it "prints an error and exits if file is not a Secret" do
      allow(YAML).to receive(:safe_load_file).with(file_path).and_return("apiVersion" => "v1", "kind" => "ConfigMap")
      expect { cli.decrypt(file_path) }.to output(/not a Kubernetes Secret/).to_stderr.and raise_error(SystemExit)
    end

    context "with a directory" do
      let(:dir) { "/tmp/secrets" }
      let(:file1) { "/tmp/secrets/a.yaml" }
      let(:file2) { "/tmp/secrets/b.yml" }

      before do
        allow(File).to receive(:directory?).with(dir).and_return(true)
        allow(Dir).to receive(:glob).and_return([file1, file2])
        allow(YAML).to receive(:safe_load_file).with(file1).and_return(content)
        allow(YAML).to receive(:safe_load_file).with(file2).and_return(content)
        allow(KubeKrypt::Decryptor).to receive(:call).and_return(decrypted_yaml)
      end

      it "processes all YAML files in the directory" do
        expect(KubeKrypt::Decryptor).to receive(:call).twice
        expect { cli.decrypt(dir) }.to output.to_stdout
      end
    end
  end
end
