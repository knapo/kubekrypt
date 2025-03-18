module KubeKrypt
  class Encryptor
    attr_reader :client, :key_name

    def initialize(key_name)
      @client = Google::Cloud::Kms.key_management_service
      @key_name = key_name
    end

    def call(plaintext)
      ciphertext = client.encrypt(name: key_name, plaintext:).ciphertext

      "#{ENC_PREFIX}:#{Base64.strict_encode64(ciphertext)}"
    end

    def self.call(content:, key_name:)
      return content unless content['data']

      encryptor = new(key_name)

      content['data'].transform_values! { |plaintext| encryptor.call(plaintext) }

      content[METADATA_KEY] = {
        KMS_KEY.to_s => key_name,
        'version' => VERSION,
        'modified_at' => Time.now.utc.iso8601
      }

      content.to_yaml
    end
  end
end
