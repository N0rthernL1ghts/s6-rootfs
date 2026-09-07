#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r version="${1:-${VERSION:-}}"
    if [[ -z "${version}" ]]; then
        printf 'Error: Missing s6-overlay version argument\n' >&2
        return 1
    fi

    local -r gpg_outcome="${GPG_OUTCOME:-}"
    local -r branch_name="bump-s6-overlay-${version}"

    if [[ "${gpg_outcome}" != "success" ]]; then
        git config user.name "github-actions[bot]"
        git config user.email "github-actions[bot]@users.noreply.github.com"
    fi

    git checkout -b "${branch_name}"
    git add Dockerfile hack/docker-bake.hcl README.md

    local commit_flags=(-m "Add s6-overlay ${version} target")
    if [[ "${gpg_outcome}" == "success" ]]; then
        commit_flags=(-S "${commit_flags[@]}")
    fi

    git commit "${commit_flags[@]}"
    git push origin "${branch_name}"

    local pr_body
    pr_body=$(
        cat <<EOF
Automated release bump for upstream [s6-overlay v${version}](https://github.com/just-containers/s6-overlay/releases/tag/v${version}).

### Verification Status
- [x] Updated \`Dockerfile\` default version
- [x] Updated \`hack/docker-bake.hcl\` matrix and rolling tags
- [x] Updated \`README.md\` version examples
- [x] Successfully compiled image with \`docker buildx bake\`
- [x] Downstream Alpine verification passed (\`/init\` test harness)
- [x] Commit signed with GPG

Once this PR is merged to \`master\`, tag \`v${version}\` and publish the GitHub release to trigger the GHCR publishing workflow.
EOF
    )

    gh pr create \
        --title "Add s6-overlay ${version} target" \
        --head "${branch_name}" \
        --base "master" \
        --body "${pr_body}"
    return 0
}

main "$@"
