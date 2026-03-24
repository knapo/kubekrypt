RSpec.describe KubeKrypt::Encryptor do
  let(:key_name) { "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key" }
  let(:kms_client) { double("KMS client") }

  before do
    allow(Google::Cloud::Kms).to receive(:key_management_service).and_return(kms_client)
  end

  describe "#call" do
    let(:encryptor) { described_class.new(key_name) }
    let(:plaintext) { "supersecret" }
    let(:ciphertext) { "raw-cipher-bytes" }
    let(:encrypt_response) { double(ciphertext: ciphertext) }

    before do
      allow(kms_client).to receive(:encrypt).with(name: key_name, plaintext: plaintext).and_return(encrypt_response)
    end

    it "returns enc-prefixed base64 encoded ciphertext" do
      expect(encryptor.call(plaintext)).to eq("enc:#{Base64.strict_encode64(ciphertext)}")
    end
  end

  describe ".call" do
    let(:ciphertext) { "cipher" }
    let(:encrypt_response) { double(ciphertext: ciphertext) }

    before do
      allow(kms_client).to receive(:encrypt).and_return(encrypt_response)
    end

    context "when content has no data key" do
      let(:content) { {"apiVersion" => "v1"} }

      it "returns content unchanged" do
        expect(described_class.call(content: content, key_name: key_name)).to eq(content)
      end
    end

    context "when content has data" do
      let(:content) do
        {
          "apiVersion" => "v1",
          "kind" => "Secret",
          "data" => {"username" => "alice", "password" => "s3cr3t"}
        }
      end

      subject(:result) { YAML.safe_load(described_class.call(content: content, key_name: key_name)) }

      it "encrypts each data value" do
        encoded = "enc:#{Base64.strict_encode64(ciphertext)}"
        expect(result["data"]).to eq("username" => encoded, "password" => encoded)
      end

      it "adds kubekrypt metadata with the kms key" do
        expect(result[KubeKrypt::METADATA_KEY]["kms_key"]).to eq(key_name)
      end

      it "adds kubekrypt metadata with the current version" do
        expect(result[KubeKrypt::METADATA_KEY]["version"]).to eq(KubeKrypt::VERSION)
      end

      it "adds kubekrypt metadata with a modified_at timestamp" do
        expect(result[KubeKrypt::METADATA_KEY]["modified_at"]).not_to be_nil
      end

      it "returns a YAML string" do
        expect(described_class.call(content: content, key_name: key_name)).to be_a(String)
      end
    end
  end
end
