[![Gem Version](https://badge.fury.io/rb/kubekrypt.svg)](https://rubygems.org/gems/kubekrypt)
[![Ruby CI](https://github.com/knapo/kubekrypt/actions/workflows/ci.yml/badge.svg)](https://github.com/knapo/kubekrypt/actions/workflows/ci.yml)

# KubeKrypt

A command-line tool for encrypting and decrypting Kubernetes Secret manifests using Google Cloud KMS.

Secret manifests can be safely committed to version control in their encrypted form and decrypted on demand — either to inspect values or to pipe directly into `kubectl`.

## Installation

```bash
gem install kubekrypt
```

Or add it to your `Gemfile`:

```ruby
gem "kubekrypt"
```

## Requirements

- Ruby >= 3.4
- A Google Cloud KMS key with `cloudkms.cryptoKeyVersions.useToEncrypt` / `useToDecrypt` permissions

## Authentication

KubeKrypt delegates authentication to the `google-cloud-kms` gem. Set one of the following environment variables:

| Variable | Description |
|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to a service account JSON key file |
| `GOOGLE_CLOUD_CREDENTIALS` | Path to JSON file, or JSON contents inline |

Application Default Credentials (e.g. `gcloud auth application-default login`) are also supported.

## Usage

### Encrypt a Secret

```bash
kubekrypt encrypt secret.yaml \
  -k projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key \
  > secret.enc.yaml
```

Overwrite the file in place with `--in-place` / `-i`:

```bash
kubekrypt encrypt -i secret.yaml -k projects/my-project/...
```

Encrypt every Secret in a directory:

```bash
kubekrypt encrypt secrets/ -k projects/my-project/...
```

Each value under `data` is encrypted individually using KMS and prefixed with `enc:`. A `kubekrypt` metadata block is embedded in the output to record the KMS key used and the version:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
data:
  token: enc:CiQAjMDkZ3...
kubekrypt:
  kms_key: projects/my-project/locations/global/keyRings/my-ring/cryptoKeys/my-key
  version: 2.1.1
  modified_at: "2026-03-24T10:00:00Z"
```

### Decrypt a Secret

```bash
kubekrypt decrypt secret.enc.yaml > secret.yaml
```

Or in place:

```bash
kubekrypt decrypt -i secret.enc.yaml
```

Decrypt every Secret in a directory:

```bash
kubekrypt decrypt -i secrets/
```

The KMS key is read from the embedded `kubekrypt` metadata — no need to specify it again.

### Decrypt and apply directly with kubectl

Kubernetes Secret `data` values must be base64-encoded. Use `--base64` to have KubeKrypt re-encode the decrypted values before output:

```bash
kubekrypt decrypt --base64 secret.enc.yaml | kubectl apply -f -
```

### Check version

```bash
kubekrypt version
```

## How it works

**Encryption:**

1. Reads the YAML file and validates it is not already encrypted.
2. Calls Google Cloud KMS to encrypt each value in the `data` map.
3. Stores ciphertext as `enc:<base64>` in place of the original value.
4. Appends a `kubekrypt` metadata block with the KMS key name, gem version, and timestamp.
5. Prints the resulting YAML to stdout.

**Decryption:**

1. Reads the `kubekrypt` metadata block to determine which KMS key to use.
2. Calls Google Cloud KMS to decrypt each `enc:<base64>` value.
3. Strips the `kubekrypt` metadata block from the output.
4. Prints the resulting YAML to stdout (optionally with base64-encoded values via `--base64`).

## Security

KubeKrypt never stores or logs key material. All cryptographic operations are performed by Google Cloud KMS — plaintext values exist only transiently in memory during a command invocation.

## Contributing

Pull requests are welcome. Please make sure `bundle exec rake ci` passes before submitting.

## License

MIT — see [LICENSE](LICENSE) for details.
