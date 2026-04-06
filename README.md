# Subconverter

**TODO: Add description**

## Building from Source

This project is built as an executable application. Its versioning is decoupled from the codebase and is designed to be injected dynamically via CI/CD pipelines (e.g., using Git tags or commit hashes).

To build a release locally (e.g., with Burrito) and inject a version, use the `APP_VERSION` environment variable:

```bash
# Example using git tags/hashes for dynamic versioning with production optimizations
MIX_ENV=prod APP_VERSION=$(git describe --tags --always) mix release
```

To run the application locally in development mode:

```bash
APP_VERSION=dev mix run --no-halt
```

