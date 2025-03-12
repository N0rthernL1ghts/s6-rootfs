ARG S6_OVERLAY_VERSION="3.2.0.2"
ARG S6_OVERLAY_RELEASE="https://github.com/just-containers/s6-overlay/releases/download"
ARG S6_OVERLAY_PAK_EXT=".tar.xz"



# Downloader stage: download s6-overlay base, binary, symlinks and checksums
FROM busybox AS downloader
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT

# Set environment variables
ENV BASE_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch${S6_OVERLAY_PAK_EXT}"
ENV BASE_HASH_URL="${BASE_URL}.sha256"
ENV BIN_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}${S6_OVERLAY_PAK_EXT}"
ENV BIN_HASH_URL="${BIN_URL}.sha256"
ENV SYMLINKS_ARCH_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch${S6_OVERLAY_PAK_EXT}"
ENV SYMLINKS_ARCH_HASH_URL="${SYMLINKS_ARCH_URL}.sha256"
ENV SYMLINKS_NOARCH_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch${S6_OVERLAY_PAK_EXT}"
ENV SYMLINKS_NOARCH_HASH_URL="${SYMLINKS_NOARCH_URL}.sha256"

RUN set -eux \
    # Replace platform
    && BIN_URL_FIXED=$(echo "${BIN_URL}" | sed -e 's/linux\///g' -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g' -e 's|arm/v7|armhf|g') \
    && BIN_HASH_URL_FIXED=$(echo "${BIN_HASH_URL}" | sed -e 's/linux\///g' -e 's/amd64/x86_64/g' -e 's/arm64/aarch64/g' -e 's|arm/v7|armhf|g') \
    # Download s6-overlay binaries
    && wget -O /s6overlay-bin.tar.xz "${BIN_URL_FIXED}" \
    && wget -O /s6overlay-bin.tar.xz.sha256 "${BIN_HASH_URL_FIXED}" \
    # Download s6-overlay base and its hash
    && wget -O /s6overlay-base.tar.xz "${BASE_URL}" \
    && wget -O /s6overlay-base.tar.xz.sha256 "${BASE_HASH_URL}" \
    # Download s6-overlay symlinks \
    && wget -O /s6overlay-arch-symlinks.tar.xz "${SYMLINKS_ARCH_URL}" \
    && wget -O /s6overlay-arch-symlinks.tar.xz.sha256 "${SYMLINKS_ARCH_HASH_URL}" \
    && wget -O /s6overlay-noarch-symlinks.tar.xz "${SYMLINKS_NOARCH_URL}" \
    && wget -O /s6overlay-noarch-symlinks.tar.xz.sha256 "${SYMLINKS_NOARCH_HASH_URL}" \
    # Build SHA256SUMS file
    && echo "$(cut -d' ' -f1 /s6overlay-base.tar.xz.sha256)  /s6overlay-base.tar.xz" > /SHA256SUMS \
    && echo "$(cut -d' ' -f1 /s6overlay-bin.tar.xz.sha256)  /s6overlay-bin.tar.xz" >> /SHA256SUMS \
    && echo "$(cut -d' ' -f1 /s6overlay-arch-symlinks.tar.xz.sha256)  /s6overlay-arch-symlinks.tar.xz" >> /SHA256SUMS \
    && echo "$(cut -d' ' -f1 /s6overlay-noarch-symlinks.tar.xz.sha256)  /s6overlay-noarch-symlinks.tar.xz" >> /SHA256SUMS \
    # Verify integrity of downloaded files
    && sha256sum -c /SHA256SUMS


# Builder stage
FROM busybox AS builder

COPY --from=downloader ["/s6overlay-base.tar.xz", "/s6overlay-bin.tar.xz", "/s6overlay-arch-symlinks.tar.xz", "/s6overlay-noarch-symlinks.tar.xz", "/tmp/s6/"]

RUN set -eux \
    && mkdir -p /build \
    && tar -Jxpf /tmp/s6/s6overlay-base.tar.xz -C /build \
    && tar -Jxpf /tmp/s6/s6overlay-bin.tar.xz -C /build \
    && tar -Jxpf /tmp/s6/s6overlay-arch-symlinks.tar.xz -C /build \
    && tar -Jxpf /tmp/s6/s6overlay-noarch-symlinks.tar.xz -C /build



# Rootfs
FROM scratch AS rootfs

COPY --from=builder ["/build/", "/"]



# Final image: minimal rootfs
FROM scratch

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>"

COPY --from=rootfs ["/", "/"]
