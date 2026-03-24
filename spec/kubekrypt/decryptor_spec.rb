RSpec.describe KubeKrypt::Decryptor do
  let(:key_name) { "projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key" }
  let(:kms_client) { double("KMS client") }

  before do
    allow(Google::Cloud::Kms).to receive(:key_management_service).and_return(kms_client)
  end

  describe "#call" do
    let(:decryptor) { described_class.new(key_name) }
    let(:plaintext) { "supersecret" }
    let(:ciphertext) { "raw-cipher-bytes" }
    let(:encodedtext) { "enc:#{Base64.strict_encode64(ciphertext)}" }
    let(:decrypt_response) { double(plaintext: plaintext) }

    before do
      allow(kms_client).to receive(:decrypt).with(name: key_name, ciphertext: ciphertext).and_return(decrypt_response)
    end

    it "returns the decrypted plaintext" do
      expect(decryptor.call(encodedtext)).to eq(plaintext)
    end

    context "with base64: true" do
      it "returns base64-encoded plaintext" do
        expect(decryptor.call(encodedtext, base64: true)).to eq(Base64.strict_encode64(plaintext))
      end
    end
  end

  describe ".call" do
    let(:plaintext) { "myvalue" }
    let(:ciphertext) { "cipher" }
    let(:encoded) { "enc:#{Base64.strict_encode64(ciphertext)}" }
    let(:decrypt_response) { double(plaintext: plaintext) }

    before do
      allow(kms_client).to receive(:decrypt).and_return(decrypt_response)
    end

    context "when content has no data key" do
      let(:content) { {"apiVersion" => "v1"} }

      it "returns content unchanged" do
        expect(described_class.call(content: content, base64: false)).to eq(content)
      end
    end

    context "when content has encrypted data" do
      let(:content) do
        {
          "apiVersion" => "v1",
          "kind" => "Secret",
          "data" => {"username" => encoded, "password" => encoded},
          KubeKrypt::METADATA_KEY => {
            "kms_key" => key_name,
            "version" => KubeKrypt::VERSION,
            "modified_at" => Time.now.utc.iso8601
          }
        }
      end

      subject(:result) { YAML.safe_load(described_class.call(content: content, base64: false)) }

      it "decrypts each data value" do
        expect(result["data"]).to eq("username" => plaintext, "password" => plaintext)
      end

      it "removes kubekrypt metadata" do
        expect(result.key?(KubeKrypt::METADATA_KEY)).to be(false)
      end

      it "returns a YAML string" do
        expect(described_class.call(content: content, base64: false)).to be_a(String)
      end

      context "with base64: true" do
        subject(:result) { YAML.safe_load(described_class.call(content: content, base64: true)) }

        it "returns base64-encoded decrypted values" do
          expect(result["data"]).to eq(
            "username" => Base64.strict_encode64(plaintext),
            "password" => Base64.strict_encode64(plaintext)
          )
        end
      end
    end
  end
end
