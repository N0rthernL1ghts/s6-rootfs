# s6-rootfs

[![Build](https://github.com/N0rthernL1ghts/s6-rootfs/actions/workflows/image.yml/badge.svg)](https://github.com/N0rthernL1ghts/s6-rootfs/actions/workflows/image.yml)
[![GitHub Release](https://img.shields.io/github/v/release/N0rthernL1ghts/s6-rootfs?color=blue&label=release)](https://github.com/N0rthernL1ghts/s6-rootfs/releases)
[![Platforms](https://img.shields.io/badge/platforms-amd64%20%7C%20arm64-lightgrey)](https://github.com/N0rthernL1ghts/s6-rootfs/pkgs/container/s6-rootfs)

`s6-rootfs` packages the [just-containers/s6-overlay](https://github.com/just-containers/s6-overlay) process supervisor into minimal, `scratch`-based container images published to the GitHub Container Registry (`ghcr.io/n0rthernl1ghts/s6-rootfs`).

It allows downstream Docker images to easily install and run the s6 supervisor stack using multi-stage builds (`COPY --from=...`).

---

## Features

- **Minimal footprint**: Assembled directly onto `scratch` containing only s6-overlay runtime files with no extraneous package managers or dependencies.
- **Multi-architecture support**: Multi-platform image manifests built for `linux/amd64` and `linux/arm64` (`linux/aarch64`).
- **Cryptographic integrity**: All upstream release artifacts (`s6-overlay-noarch`, platform binaries, and symlinks) are verified against upstream SHA256 checksums during build.
- **Complete v3 components**: Includes noarch base scripts, platform binaries, and standard symlinks (`/init`, `/command`, `/package`).
- **Automated builds**: Built and published automatically via Docker Bake and GitHub Actions.

---

## Usage

```dockerfile
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:latest ["/", "/"]
```

or with fixed version:

```dockerfile
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:3.2.3.2 ["/", "/"]
```

### Recommended Integration Example

```dockerfile
# ---------------------
# Build root filesystem
# ---------------------
FROM scratch AS rootfs

# Copy over base files
COPY ["./rootfs", "/"]

# Install S6
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:3.2.3.2 ["/", "/"]


# ---------------------
# Build image
# ---------------------
FROM alpine:latest

COPY --from=rootfs ["/", "/"]
RUN apk add --update --no-cache nano

# S6 configuration - not required
# See: https://github.com/just-containers/s6-overlay#customizing-s6-overlay-behaviour
ENV S6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_CMD_RECEIVE_SIGNALS=1

# Important, this is required for S6 to work
ENTRYPOINT ["/init"]
```

---

## Tagging & Versioning

Images are published to `ghcr.io/n0rthernl1ghts/s6-rootfs`.

| Tag Scheme | Example | Description |
| :--- | :--- | :--- |
| `latest` | `ghcr.io/n0rthernl1ghts/s6-rootfs:latest` | Points to the latest stable s6-overlay release (`3.2.3.2`). |
| `<major>.<minor>` | `ghcr.io/n0rthernl1ghts/s6-rootfs:3.2` | Rolling tag for the active minor release branch. |
| `<major>.<minor>.<patch>` | `ghcr.io/n0rthernl1ghts/s6-rootfs:3.2.3` | Rolling tag for the active patch release branch. |
| `<exact_version>` | `ghcr.io/n0rthernl1ghts/s6-rootfs:3.2.3.2` | Pinned exact upstream release version (recommended for production). |
| `2.x` (Legacy) | `ghcr.io/n0rthernl1ghts/s6-rootfs:2.2.0.3` | Legacy s6-overlay v2.x releases maintained for backward compatibility. |

> [!NOTE]
> Container images previously hosted on Docker Hub (`docker.io/nlss/s6-rootfs`) have been discontinued in favor of GitHub Container Registry (`ghcr.io`).

---

## Supported Architectures

Images are built natively or via QEMU for the following architectures:

- `linux/amd64`
- `linux/arm64` (aarch64)

---

## Local Development & Builds

Builds are defined in [`build/docker-bake.hcl`](build/docker-bake.hcl) using Docker Buildx Bake.

### Build a specific version locally

```bash
# Build target 3_2_3_2 using Bake
docker buildx bake --file build/docker-bake.hcl 3_2_3_2

# Build and load into local Docker daemon for host architecture
docker buildx bake --file build/docker-bake.hcl --set "*.platform=linux/amd64" --load 3_2_3_2
```

### Standalone Dockerfile build

```bash
docker build \
  --build-arg S6_OVERLAY_VERSION="3.2.3.2" \
  -t s6-rootfs:3.2.3.2 \
  .
```

### Downstream Test Harness

Verify the built image with a downstream container test:

```bash
docker run --rm -i $(docker build -q - <<EOF
FROM alpine:latest
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:3.2.3.2 ["/", "/"]
ENTRYPOINT ["/init"]
CMD ["/bin/sh", "-c", "echo 's6-overlay initialized successfully'"]
EOF
)
```

---

## References

- [just-containers/s6-overlay](https://github.com/just-containers/s6-overlay): Official upstream s6-overlay project repository and documentation.
- [s6 Supervision Suite](https://skarnet.org/software/s6/): Documentation on s6 process supervision suite by Laurent Bercot (skarnet.org).
