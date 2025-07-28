lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kubekrypt/version'

Gem::Specification.new do |spec|
  spec.name = 'kubekrypt'
  spec.version = KubeKrypt::VERSION
  spec.authors = ['Krzysztof Knapik']
  spec.email = ['knapo@knapo.net']

  spec.summary = 'KubeKrypt provides seamless encryption and decryption of Kubernetes Secret menifests using Google Cloud KMS'
  spec.homepage = 'https://github.com/knapo/kubekrypt'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = 'https://github.com/knapo/kubekrypt'
  spec.metadata['source_code_uri'] = 'https://github.com/knapo/kubekrypt'
  spec.metadata['changelog_uri'] = 'https://github.com/knapo/kubekrypt/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.4.0')

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(bin/|spec/|\.rub)}) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'google-cloud-kms'
  spec.add_dependency 'grpc', '< 1.74.0' # 1.74.0 & google-cloud-kms produce segmentation fault errors
  spec.add_dependency 'thor', '>= 1.0'
  spec.add_dependency 'yaml'
end
