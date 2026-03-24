module KubeKrypt
  class CLI < Thor
    include Thor::Shell

    def self.exit_on_failure?
      true
    end

    desc "version", "Displays the current version of KubeKrypt"
    def version
      puts KubeKrypt::VERSION
    end

    method_option KMS_KEY, aliases: "-k", desc: "Google KMS encryption key id to use", required: true
    desc "encrypt FILE", "Encrypts Kubernetes secrets manifest using the specified KMS key"
    def encrypt(file_path)
      yaml_content = File.read(file_path)
      content = YAML.safe_load(yaml_content)
      key_name = options.fetch(KMS_KEY)

      raise AlreadyEncryptedError, "#{file_path} is already encrypted" if content[METADATA_KEY]

      result = KubeKrypt::Encryptor.call(content:, key_name:)
      puts result
    rescue AlreadyEncryptedError, NotEncryptedError => e
      warn "Error: #{e.message}"
      exit 1
    rescue Errno::ENOENT
      warn "Error: file not found: #{file_path}"
      exit 1
    rescue => e
      warn "Error: #{e.message}"
      exit 1
    end

    method_option :base64, desc: "Base64 encoded values", type: :boolean, required: false
    desc "decrypt FILE", "Decrypts Kubernetes secrets manifest using embedded kubekrypt metadata"
    def decrypt(file_path)
      yaml_content = File.read(file_path)
      content = YAML.safe_load(yaml_content)
      base64 = options.fetch(:base64, false)

      raise NotEncryptedError, "#{file_path} is not encrypted" unless content[METADATA_KEY]

      result = KubeKrypt::Decryptor.call(content:, base64:)
      puts result
    rescue AlreadyEncryptedError, NotEncryptedError => e
      warn "Error: #{e.message}"
      exit 1
    rescue Errno::ENOENT
      warn "Error: file not found: #{file_path}"
      exit 1
    rescue => e
      warn "Error: #{e.message}"
      exit 1
    end
  end
end
