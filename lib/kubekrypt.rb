require 'base64'
require 'google/cloud/kms'
require 'optparse'
require 'thor'
require 'yaml'

module KubeKrypt
  AlreadyEncrytpedError = Class.new(StandardError)
  NotEncrytpedError = Class.new(StandardError)
  KMS_KEY = :kms_key
  ENCRYPTION_METHOD = 'aes-256-gcm'.freeze
  METADATA_KEY = 'kubekrypt'.freeze
  ENC_PREFIX = 'enc'.freeze
end

require 'kubekrypt/version'
require 'kubekrypt/cli'
require 'kubekrypt/encryptor'
require 'kubekrypt/decryptor'
