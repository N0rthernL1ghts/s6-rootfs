# First stage - Download s6-overlay
ARG DOWNLOADER_ALPINE_VERSION=3.15

# First stage - Download s6-overlay and unpack it
FROM --platform=${TARGETPLATFORM} alpine:${DOWNLOADER_ALPINE_VERSION} AS downloader

ARG TARGETPLATFORM

# S6 Overlay
ARG S6_OVERLAY_VERSION="3.0.0.0-1"
ARG S6_OVERLAY_RELEASE="https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}.tar.gz"

RUN wget -O /tmp/s6overlay.tar.gz $(echo ${S6_OVERLAY_RELEASE} | sed 's/linux\///g' | sed 's/arm64/aarch64/g' | sed 's/arm\/v7/armhf/g') \
    && mkdir -p /s6-overlay \
    && tar xzf /tmp/s6overlay.tar.gz -C /s6-overlay


# Final stage
FROM scratch AS s6-rootfs

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>"

COPY --from=downloader ["/s6-overlay/", "/"]