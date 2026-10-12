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

# Check if the commands required in this repository command can be executed.
function _check_command()
{
  local cmd="$1"

  if ! command -v "${cmd}" > /dev/null 2>&1
  then
    echo "::error::Missing dependency: \`${cmd}\`." \
      "Please, install it by running \`brew install ${cmd}\`" \
      "and ensure it is added to your \`PATH\`." >&2
    exit 1
  fi
}

_check_command "git"
_check_command "gh"
_check_command "jq"
_check_command "diff"
_check_command "shfmt"
_check_command "shellcheck"
