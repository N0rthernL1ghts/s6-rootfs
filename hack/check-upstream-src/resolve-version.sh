#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r github_output="${GITHUB_OUTPUT:-/dev/null}"
    local -r github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
    local -r manual_version="${1:-${MANUAL_VERSION:-}}"

    local raw_version=""
    if [[ -n "${manual_version}" ]]; then
        raw_version="${manual_version}"
    fi
    if [[ -z "${manual_version}" ]]; then
        raw_version=$(gh api repos/just-containers/s6-overlay/releases/latest --jq .tag_name)
    fi

    local -r version="${raw_version#v}"
    printf 'Target s6-overlay version: %s\n' "${version}"

    # Check if tag already exists in local repo
    if git rev-parse "v${version}" >/dev/null 2>&1; then
        printf '::notice::Version v%s is already released in this repository.\n' "${version}"
        printf '### Up to date\ns6-rootfs already contains tag \x60v%s\x60. No update needed.\n' "${version}" >>"${github_step_summary}"
        printf 'skip=true\n' >>"${github_output}"
        return 0
    fi

    # Check if remote branch already exists
    if git ls-remote --exit-code --heads origin "bump-s6-overlay-${version}" >/dev/null 2>&1; then
        printf '::notice::Branch bump-s6-overlay-%s already exists on remote.\n' "${version}"
        printf 'skip=true\n' >>"${github_output}"
        return 0
    fi

    printf 'skip=false\n' >>"${github_output}"
    printf 'version=%s\n' "${version}" >>"${github_output}"
    return 0
}

main "$@"
