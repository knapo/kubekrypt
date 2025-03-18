module KubeKrypt
  class Decryptor
    attr_reader :client, :key_name

    def initialize(key_name)
      @client = Google::Cloud::Kms.key_management_service
      @key_name = key_name
    end

    def call(encodedtext, base64: false)
      ciphertext = Base64.strict_decode64(encodedtext.sub("#{ENC_PREFIX}:", ''))

      result = client.decrypt(name: key_name, ciphertext:).plaintext

      if base64
        Base64.strict_encode64(result)
      else
        result
      end
    end

    def self.call(content:, base64:)
      return content unless content['data']

      key_name = content.fetch(METADATA_KEY).fetch(KMS_KEY.to_s)
      decryptor = new(key_name)
      content['data'].transform_values! { |encodedtext| decryptor.call(encodedtext, base64:) }
      content.delete(METADATA_KEY)
      content.to_yaml
    end
  end
end
