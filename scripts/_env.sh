#!/bin/bash
# Set of environment variable definitions.
# **WARNING:** When sourcing this file, current directory will be always moved
# to the repository root, as required by all the scripts in this repository.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `COMMITTER_NAME`: The name of the committer.
# - `COMMITTER_USERNAME`: The username of the committer.
# - `COMMITTER_EMAIL`: The email address of the committer.
# - `PR_LABEL`: Label for the pull requests created by `brew bump`.
# - `GITHUB_OUTPUT`: Used to write output.
#

# Include guard.
if [[ -n "${__ENV_SH}" ]]
then
  return 0
fi
export __ENV_SH="1"

# Environment variables.
export TAP_NAME="${TAP_NAME:-"TheBusyDev/tap"}"
export GH_TOKEN="${GH_TOKEN:-}"
export COMMITTER_NAME="${COMMITTER_NAME:-}"
export COMMITTER_USERNAME="${COMMITTER_USERNAME:-"TheBusyDev"}"
export COMMITTER_EMAIL="${COMMITTER_EMAIL:-}"
export PR_LABEL="${PR_LABEL:-"autobump"}"
export GITHUB_OUTPUT="${GITHUB_OUTPUT:-"github_output.log"}"

export HOMEBREW_GITHUB_API_TOKEN="${GH_TOKEN}"
export HOMEBREW_GIT_COMMITTER_NAME="${COMMITTER_NAME}"
export HOMEBREW_GIT_COMMITTER_EMAIL="${COMMITTER_EMAIL}"

# Change directory to the repository root.
cd "$(dirname "$0")"/.. || exit 1

# Check if `brew` is installed.
if ! command -v "brew" > /dev/null 2>&1
then
  echo "::error::Missing dependency: \`brew\`." \
    "Visit https://brew.sh/ and install it! Cheers!" >&2
  exit 1
fi

# Check if the dependencies required in this repository command can be executed.
brew bundle check --file=.Brewfile --verbose || {
  echo "::error::Missing dependencies from \`brew\`." \
    "Install them by running \`brew bundle install --file=.Brewfile\`. Cheers!"
  exit 1
}

return 0
