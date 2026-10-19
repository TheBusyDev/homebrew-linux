#!/bin/bash
# Clean up all the branches on remote starting with `bump-*`.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_REPO_NAME`: The name of the GitHub repository.
# - `BRANCH_PREFIX`: The prefix of the branches to be deleted.
# - `GH_DELETE_DRYRUN`: If set, only find branches without deleting them.
#

set -euo pipefail

export GH_REPO_NAME="${GH_REPO_NAME:-"TheBusyDev/homebrew-linux"}"
export BRANCH_PREFIX="${BRANCH_PREFIX:-"bump-"}"
export GH_DELETE_DRYRUN="${GH_DELETE_DRYRUN:-}"

mapfile -t bump_branches < <(
  gh api --paginate "repos/${GH_REPO_NAME}/branches" \
    --jq ".[].name | select(startswith(\"${BRANCH_PREFIX}\"))"
)
all_deleted=true # Has all the branches deleted successfully?

for branch in "${bump_branches[@]}"
do
  echo "==> Deleting ${branch}..."
  if [[ -z "${GH_DELETE_DRYRUN}" ]]
  then
    gh api -X DELETE "repos/${GH_REPO_NAME}/git/refs/heads/${branch}" \
      || {
        echo "::error::Cannot delete branch \`${branch}\`."
        all_deleted=false
      }
  fi
done

${all_deleted} || exit 1

echo "Deleted ${#bump_branches[@]} branch(es)."
exit 0
