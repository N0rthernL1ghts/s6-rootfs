#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r version="${1:-${VERSION:-}}"
    if [[ -z "${version}" ]]; then
        printf 'Error: Missing s6-overlay version argument\n' >&2
        return 1
    fi

    local -r run_url="${RUN_URL:-${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/${GITHUB_RUN_ID:+actions/runs/}${GITHUB_RUN_ID:-}}"

    local pending_issue
    pending_issue=$(gh issue list --state open --search "[Automation] Failed to build s6-overlay ${version}" --json number --jq '.[0].number // empty')
    if [[ -n "${pending_issue}" ]]; then
        printf 'Existing failure issue #%s is already open. Skipping duplicate issue creation.\n' "${pending_issue}"
        return 0
    fi

    local body
    body=$(
        cat <<EOF
Automated build for upstream release [v${version}](https://github.com/just-containers/s6-overlay/releases/tag/v${version}) failed during local build or downstream verification.

- **Target Version:** \`${version}\`
- **Run URL:** ${run_url}

Please inspect the workflow execution log to investigate the packaging failure.
EOF
    )

    gh issue create \
        --title "[Automation] Failed to build s6-overlay ${version}" \
        --label "bug,build-failure" \
        --body "${body}"
    return 0
}

main "$@"
