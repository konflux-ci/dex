# Dex Konflux Build

This repository contains the build configuration for creating Dex container images using Konflux CI. The upstream Dex project is included as a git submodule.

## Overview

This repository provides:

- **Containerfile**: Multi-stage build configuration using Red Hat UBI images
- **Git submodule**: Links to the upstream dex project
- **Konflux integration**: Automated CI/CD pipeline configuration

## Quick Start

Initialize the submodule:

```bash
git submodule update --init --recursive
```

> **Note:** The submodule is configured to track tags (not branches) for automated dependency updates via MintMaker/Renovate. This means `git submodule update --remote` will not work as expected. To manually update the submodule to a different tag, navigate to the submodule directory and run:

```bash
cd dex
git fetch && git checkout <branch | tag-name>
```

depending on if you want to checkout a branch or a tag.

Build locally using Podman:

```bash
podman build -f Containerfile -t dex --build-arg DEX_VERSION=v2.43.0 .
```

## Local Development

For local testing and development, you can use the upstream project's build system:

```bash
cd dex
make build
```

## Local Testing

You can run the built image locally to ensure it starts correctly.

### Create a Configuration File

Dex requires a configuration file to start. Create a minimal `config-dev.yaml` for testing:

```yaml
issuer: http://127.0.0.1:5556/dex
storage:
  type: memory
web:
  http: 0.0.0.0:5556
logger:
  level: "debug"
connectors:
- type: mockCallback
  id: mock
  name: Mock
```

### Run the Container

Mount the config file and expose the port:

```bash
podman run --rm \
  -p 5556:5556 \
  -v $(pwd)/config-dev.yaml:/etc/dex/config.yaml:Z \
  localhost/dex serve /etc/dex/config.yaml
```

### Verify Health

```bash
curl http://127.0.0.1:5556/dex/healthz
# Output: ok or health check passed
```

## Submodule Updates

This repository uses MintMaker/Renovate to automatically update the git submodule when new stable semantic version tags are released upstream. The `.gitmodules` file is configured with `branch = v2.43.x` to track tags rather than branches.

> **Important:** This configuration disrupts the native Git submodule update workflow. The standard `git submodule update --remote` command will fail with an error like `fatal: Unable to find refs/remotes/origin/v2.43.x revision in submodule path...` because Git expects the branch field to reference an actual branch, not a tag.

To manually update the submodule to a specific tag:

```bash
cd dex
git fetch --tags
git checkout <branch> | <tag-name>
cd ..
git add dex
git commit -m "Update submodule to <branch | tag-name>"
```

depending on if you want to checkout a branch or a tag.

Renovate will automatically create pull requests when new tags matching semantic versioning are available upstream.

## Version Information

- **Current stable version:** v2.43.x
- **Go version:** 1.24 (via UBI9 go-toolset)
- **Supported architectures:** linux/amd64

## Upstream Project

For complete documentation, features, and usage instructions, please refer to the upstream project:

- [Dex Documentation](https://dexidp.io/docs/)
- [Upstream Repository](https://github.com/dexidp/dex)

## Konflux Integration

This repository is designed to work with Konflux CI/CD pipelines. The actual container builds are handled by Konflux using their own build task and the provided Containerfile.

### Konflux Build Process

- **Automated builds**: Konflux automatically builds containers when changes are pushed
- **Submodule management**: Konflux handles submodule updates via MintMaker
- **Security scanning**: Konflux runs security scans and compliance checks
- **Registry publishing**: Konflux pushes built images to configured registries

### Local Testing vs Konflux Builds

| Aspect | Local Podman Build | Konflux Build |
| :--- | :--- | :--- |
| Purpose | Local testing and validation | Production builds |
| Trigger | Manual execution | Automated on git changes |
| Environment | Your local machine | Konflux build environment |
| Security | Basic build validation | Full security scanning |
| Registry | Local/optional push | Automated registry push |
| Compliance | Not applicable | Full compliance checks |

## Containerfile Features

The Containerfile provides:

- **Red Hat UBI base images**: Uses UBI9 Go toolset for building and UBI10 Micro for runtime
- **Multi-stage builds**: Optimized image size with separate build and runtime stages
- **CGO enabled**: Full SQLite3 database support
- **Layer caching optimization**: Dependencies downloaded only when go.mod changes
- **Proper labeling**: OCI-compliant labels for traceability and compliance metadata
- **Root certificates**: Includes CA certificates for TLS connections

## License

This build configuration follows the same Apache 2.0 license as the upstream Dex project.
