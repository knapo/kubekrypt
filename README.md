[![Gem Version](https://badge.fury.io/rb/kubekrypt.svg)](https://rubygems.org/gems/kubekrypt)

# KubeKrypt

A command-line tool for securely encrypting and decrypting Kubernetes Secret manifests using KMS encryption keys.

## Overview

KubeKrypt provides a simple and secure way to manage sensitive information in Kubernetes Secret manifests. It allows you to encrypt Secret manifests before they're stored in version control systems, and decrypt them when they need to be applied to a cluster.

## Features

- **Secure Encryption**: Uses KMS to encrypt sensitive data in Kubernetes Secret manifests
- **Simple Interface**: Easy-to-use CLI commands for encryption and decryption
- **Metadata Tracking**: Embeds metadata in encrypted files for tracking and verification
- **Stdout Integration**: Outputs to standard out for easy piping and redirection
- **Base64 Processing**: Automatically handles base64 encoding/decoding under the hood, maintaining compatibility with Kubernetes Secret format

## Installation

`kubecrypt` uses `google-cloud-kms` and it requires an [environment variable](https://cloud.google.com/ruby/docs/reference/google-cloud-kms/latest/AUTHENTICATION) to be set in order to authenticate and work properly.
You need one of:

- `GOOGLE_CLOUD_CREDENTIALS` - Path to JSON file, or JSON contents
- `GOOGLE_APPLICATION_CREDENTIALS` - Path to JSON file

## Usage

### Encrypting a Secret

```bash
kubekrypt encrypt secret.yaml -k projects/your-project/locations/global/keyRings/your-keyring/cryptoKeys/your-key > secret.enc.yaml
```

### Decrypting a Secret

```bash
kubekrypt decrypt secret.enc.yaml > secret.yaml
```

### Piping to kubectl

```bash
kubekrypt decrypt --base64 secret.enc.yaml | kubectl apply -f -
```

### Checking Version

```bash
kubekrypt version
```

## How It Works

1. KubeKrypt reads your Kubernetes Secret YAML file
2. For encryption, it:
   - Validates that it's a proper Kubernetes Secret
   - Ensures it's not already encrypted
   - Decodes base64 values to get raw data
   - Uses KMS to encrypt sensitive data
   - Re-encodes with base64 as needed
   - Adds metadata about the encryption
   - Outputs the encrypted YAML

3. For decryption, it:
   - Verifies the file contains KubeKrypt encryption metadata
   - Uses the embedded information to decrypt the data
   - Handles all necessary base64 encoding/decoding
   - Outputs the original Secret YAML

## Security

KubeKrypt never stores encryption keys locally. All encryption and decryption operations are performed using KMS, ensuring that key material is never exposed.

## Requirements

- Ruby 3.4+
- Access to a KMS key with appropriate permissions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
