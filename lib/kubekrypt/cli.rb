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
    method_option :in_place, aliases: "-i", desc: "Write output back to the source file", type: :boolean, default: false
    desc "encrypt FILE [FILE ...]", "Encrypts Kubernetes Secret manifests using the specified KMS key"
    def encrypt(*paths)
      key_name = options.fetch(KMS_KEY)
      in_place = options[:in_place]

      expand(paths).each { |file_path| process_encrypt(file_path, key_name:, in_place:) }
    end

    method_option :base64, desc: "Base64 encoded values", type: :boolean, required: false
    method_option :in_place, aliases: "-i", desc: "Write output back to the source file", type: :boolean, default: false
    desc "decrypt FILE [FILE ...]", "Decrypts Kubernetes Secret manifests using embedded kubekrypt metadata"
    def decrypt(*paths)
      base64 = options.fetch(:base64, false)
      in_place = options[:in_place]

      expand(paths).each { |file_path| process_decrypt(file_path, base64:, in_place:) }
    end

    private

    def expand(paths)
      paths.flat_map do |path|
        if File.directory?(path)
          Dir.glob(File.join(path, "**", "*.{yaml,yml}")).sort
        else
          [path]
        end
      end
    end

    def load_secret(file_path)
      content = YAML.safe_load_file(file_path)
      raise InvalidSecretError, "#{file_path} is not a Kubernetes Secret" unless content["kind"] == "Secret"
      content
    rescue Psych::Exception => e
      raise InvalidSecretError, "#{file_path} is not valid YAML: #{e.message}"
    end

    def write_output(result, file_path:, in_place:)
      if in_place
        File.write(file_path, result)
      else
        puts result
      end
    end

    def process_encrypt(file_path, key_name:, in_place:)
      content = load_secret(file_path)
      raise AlreadyEncryptedError, "#{file_path} is already encrypted" if content[METADATA_KEY]

      result = KubeKrypt::Encryptor.call(content:, key_name:)
      write_output(result, file_path:, in_place:)
    rescue AlreadyEncryptedError, NotEncryptedError, InvalidSecretError => e
      warn "Error: #{e.message}"
      exit 1
    rescue Errno::ENOENT
      warn "Error: file not found: #{file_path}"
      exit 1
    rescue => e
      warn "Error: #{e.message}"
      exit 1
    end

    def process_decrypt(file_path, base64:, in_place:)
      content = load_secret(file_path)
      raise NotEncryptedError, "#{file_path} is not encrypted" unless content[METADATA_KEY]

      result = KubeKrypt::Decryptor.call(content:, base64:)
      write_output(result, file_path:, in_place:)
    rescue AlreadyEncryptedError, NotEncryptedError, InvalidSecretError => e
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
