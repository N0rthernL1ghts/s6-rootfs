ARG S6_OVERLAY_VERSION="3.0.0.2"
ARG S6_OVERLAY_RELEASE="https://github.com/just-containers/s6-overlay/releases/download/"
ARG S6_OVERLAY_PAK_EXT=".tar.xz"

# First stage - Download s6-overlay noarch base and unpack it
FROM scratch AS downloader-s6-base
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT
ADD "${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-noarch${S6_OVERLAY_PAK_EXT}" /s6overlay-base.tar.xz


# Second stage - Download s6-overlay platform-dependent binaries and unpack
FROM --platform=${TARGETPLATFORM} alpine:3.16.2 AS downloader-s6-bin
ARG TARGETPLATFORM
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_RELEASE
ARG S6_OVERLAY_PAK_EXT
ARG S6_OVERLAY_RELEASE_URL="${S6_OVERLAY_RELEASE}/v${S6_OVERLAY_VERSION}/s6-overlay-${TARGETPLATFORM}${S6_OVERLAY_PAK_EXT}"

RUN apk add --no-cache wget \
    && wget -O /s6overlay-bin.tar.xz "$(echo ${S6_OVERLAY_RELEASE_URL} | sed 's/linux\///g' | sed 's/amd64/x86_64/g' | sed 's/arm64/aarch64/g' | sed 's/arm\/v7/armhf/g')"


# Third stage - Build rootfs from s6 parts
FROM alpine:3.16.2 AS rootfs-builder

COPY --from=downloader-s6-base ["/s6overlay-base.tar.xz", "/s6overlay-base.tar.xz"]
COPY --from=downloader-s6-bin  ["/s6overlay-bin.tar.xz", "/s6overlay-bin.tar.xz"]

WORKDIR "/rootfs-build/"

RUN apk add --no-cache tar xz \
    && tar -Jxpf /s6overlay-base.tar.xz -C /rootfs-build \
    && tar -Jxpf /s6overlay-bin.tar.xz -C /rootfs-build


# Final stage
FROM scratch AS s6-rootfs

LABEL maintainer="Aleksandar Puharic <aleksandar@puharic.com>"

COPY --from=rootfs-builder ["/rootfs-build/", "/"]