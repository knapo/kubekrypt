# Changelog

## [2.0.1] - 2025-03-21

### Added
- Better error handling and more descriptive errors

## [2.0.0] - 2025-03-18

### Added
- Core encryption functionality using KMS for securing Kubernetes Secret manifests
- Command-line interface with encrypt and decrypt commands
- Support for reading YAML Secret manifests from files
- Automatic detection of already encrypted files
- Metadata tagging to track encryption details within manifests
- Version command to display current KubeKrypt version

### Features
- **Encrypt Command**: Securely encrypts Kubernetes Secret manifests using specified KMS key
- **Decrypt Command**: Decrypts previously encrypted manifests using embedded metadata
- **YAML Output**: All commands output properly formatted YAML to stdout for easy redirection

### Implementation Details
- Uses Thor for CLI command parsing
- Preserves original manifest structure while securing sensitive data
- Adds `kubekrypt` metadata section to encrypted manifests for tracking
- Basic error handling for common failure scenarios
