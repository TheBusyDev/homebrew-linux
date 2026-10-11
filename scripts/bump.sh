#!/bin/bash
# Update `version` and `sha265` for all the formulae/casks from the provided tap.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `COMMITTER_NAME`: The name of the committer.
# - `COMMITTER_USERNAME`: The username of the committer.
# - `COMMITTER_EMAIL`: The email address of the committer.
# - `PR_LABEL`: Label for the pull requests created by `brew bump`.
# - `GITHUB_OUTPUT`: Used to write output.
#
# Input:
# 1. The name of the tap to be updated.
#
# Output (written into `GITHUB_OUTPUT`):
# - `pr_numbers`: Colon-separated list of pull requests numbers created by
#                 `brew bump`.
#

source ./scripts/_functions.sh

# Useful variables.
export HOMEBREW_GITHUB_API_TOKEN="$GH_TOKEN"
export HOMEBREW_GIT_COMMITTER_NAME="$COMMITTER_NAME"
export HOMEBREW_GIT_COMMITTER_EMAIL="$COMMITTER_EMAIL"

pr_numbers="" # Colon-separated list of PR numbers created by `brew bump`.

# Get formulae and casks from the tap.
mapfile -t formulae < <(formulae_from_tap "$1")
mapfile -t casks < <(casks_from_tap "$1")

# Update formulae from the given tap.
echo "==> Updating formulae..."

for formula in "${formulae[@]}"; do
  brew_bump_formula "$formula"
  pr_numbers+=":$(get_latest_pr_number "$PR_LABEL")"
done

# Update casks from the given tap.
echo "==> Updating casks..."

for cask in "${casks[@]}"; do
  brew_bump_cask "$cask"
  pr_numbers+=":$(get_latest_pr_number "$PR_LABEL")"
done

# Export PR numbers.
pr_numbers="${pr_numbers%:}"
pr_numbers="${pr_numbers#:}"
echo "pr_numbers=$pr_numbers" >> "$GITHUB_OUTPUT"

exit 0
