#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r github_output="${GITHUB_OUTPUT:-/dev/null}"
    local -r github_step_summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"

    # Check for any open PRs created for an s6-overlay update
    local pending_pr
    pending_pr=$(gh pr list --state open --search "Add s6-overlay in:title" --json number --jq '.[0].number // empty')
    if [[ -n "${pending_pr}" ]]; then
        printf '::notice::Found pending release PR #%s. Halting automation until resolved.\n' "${pending_pr}"
        printf '### Automation Paused\nAn existing release PR (#%s) is pending review/merge. Automation halted to avoid branching conflicts.\n' "${pending_pr}" >>"${github_step_summary}"
        printf 'proceed=false\n' >>"${github_output}"
        return 0
    fi

    # Check for any open build failure issues requiring manual intervention
    local pending_issue
    pending_issue=$(gh issue list --state open --label "build-failure" --json number --jq '.[0].number // empty')
    if [[ -n "${pending_issue}" ]]; then
        printf '::notice::Found unresolved failure issue #%s. Halting automation for manual intervention.\n' "${pending_issue}"
        printf '### Automation Paused\nUnresolved issue #%s labeled \x60build-failure\x60 is currently open. Automation halted for manual triage.\n' "${pending_issue}" >>"${github_step_summary}"
        printf 'proceed=false\n' >>"${github_output}"
        return 0
    fi

    printf 'proceed=true\n' >>"${github_output}"
    return 0
}

main "$@"
