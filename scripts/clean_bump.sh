#!/bin/bash
# Clean up all the branches on remote starting with `bump-*`.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_REPO_NAME`: The name of the GitHub repository.
# - `GH_DELETE_DRYRUN`: If set, only find branches without deleting them.
# - `BUMP_BRANCH_PREFIX`: The prefix of the branches created by `brew bump`.
#

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh

mapfile -t bump_branches < <(
  gh api --paginate "repos/${GH_REPO_NAME}/branches" \
    --jq ".[].name | select(startswith(\"${BUMP_BRANCH_PREFIX}\"))"
)

n_deleted=0 # Number of deleted branches.

for branch in "${bump_branches[@]}"
do
  mapfile -t open_prs < <(
    gh pr list --head "${branch}" --state open \
      --json "number" --jq ".[].number"
  )

  if ((${#open_prs[@]} > 0))
  then
    echo "==> Skipping \`${branch}\` (found open PRs)..."
    continue
  fi

  echo "==> Deleting \`${branch}\`..."
  if [[ -z "${GH_DELETE_DRYRUN}" ]]
  then
    gh api -X DELETE "repos/${GH_REPO_NAME}/git/refs/heads/${branch}" \
      || echo "::error::Cannot delete branch \`${branch}\`." >&2
  fi
  ((++n_deleted))
done

n_skipped=$((n_deleted - ${#bump_branches[@]})) # Number of skipped branches.
echo "Skipped ${n_skipped} branch(es)."
echo "Deleted ${n_deleted} branch(es)."

((n_skipped == 0)) || exit 1
exit 0
