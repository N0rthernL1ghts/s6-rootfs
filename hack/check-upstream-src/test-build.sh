#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r version="${1:-${VERSION:-}}"
    if [[ -z "${version}" ]]; then
        printf 'Error: Missing s6-overlay version argument\n' >&2
        return 1
    fi

    local -r target_name="${version//[.-]/_}"

    printf 'Building target %s locally for linux/amd64...\n' "${target_name}"
    docker buildx bake --file hack/docker-bake.hcl --set "*.platform=linux/amd64" --load "${target_name}"

    printf 'Running downstream test container...\n'
    local test_image
    test_image=$(
        docker build -q - <<EOF
FROM alpine:latest
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:${version} / /
ENTRYPOINT ["/init"]
CMD ["/bin/sh", "-c", "echo 'S6 initialized successfully'"]
EOF
    )

    docker run --rm -i "${test_image}"

    printf 'Verifying s6 binaries...\n'
    docker run --rm "ghcr.io/n0rthernl1ghts/s6-rootfs:${version}" /bin/sh -c "test -x /init && test -d /command"

    printf 'Build and downstream verification passed for %s!\n' "${version}"
    return 0
}

main "$@"
