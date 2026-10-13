#!/bin/bash
# Update `version` and `sha265` for all the formulae/casks from the provided tap.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap to be updated.
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `COMMITTER_NAME`: The name of the committer.
# - `COMMITTER_USERNAME`: The username of the committer.
# - `COMMITTER_EMAIL`: The email address of the committer.
# - `PR_LABEL`: Label for the pull requests created by `brew bump`.
# - `GITHUB_OUTPUT`: Used to write output.
#
# Output (written into `GITHUB_OUTPUT`):
# - `pr_numbers`: Colon-separated list of pull requests numbers created by
#                 `brew bump`.
#

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

# Useful variables.
pr_numbers="" # Colon-separated list of PR numbers created by `brew bump`.

# Get formulae and casks from the tap.
mapfile -t formulae < <(formulae_from_tap)
mapfile -t casks < <(casks_from_tap)

# Update formulae from the given tap.
echo "==> Updating formulae..."

for formula in "${formulae[@]}"
do
  brew_bump_formula "${formula}"
  sleep "${GH_COOLDOWN}"
  pr_numbers+=":$(get_latest_pr_number)"
done

# Update casks from the given tap.
echo "==> Updating casks..."

for cask in "${casks[@]}"
do
  brew_bump_cask "${cask}"
  sleep "${GH_COOLDOWN}"
  pr_numbers+=":$(get_latest_pr_number)"
done

# Export PR numbers.
pr_numbers="${pr_numbers%:}"
pr_numbers="${pr_numbers#:}"
echo "pr-numbers=${pr_numbers}" >> "${GITHUB_OUTPUT}"

exit 0
