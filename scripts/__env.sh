#!/bin/bash
# Set environment variables and check dependencies (as listed in `.deps` file).
# **WARNING:** When sourcing this file, current directory will be always moved
# to the repository root, as required by all the scripts in this repository.
#
# Required global variables:
# - `TAP_NAME`: The name of the tap.
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `COMMITTER_NAME`: The name of the committer.
# - `COMMITTER_USERNAME`: The username of the committer.
# - `COMMITTER_EMAIL`: The email address of the committer.
# - `PR_LABEL`: Label for the pull requests created by `brew bump`.
# - `GITHUB_OUTPUT`: Used to write output.
# - `HOMEBREW_BUMP_DRYRUN_PR_NUMBER`:
#     Enable dry-runs for `brew bump` and do not open a new pull request.
#     Instead, use $HOMEBREW_BUMP_DRYRUN_PR_NUMBER as dummy PR
#     (useful for debugging).
#

# Include guard.
[[ -v __ENV_SH ]] && return 0
readonly __ENV_SH=1

# Apply shell options.
set -euo pipefail

# Environment variables.
export TAP_NAME="${TAP_NAME:-"thebusydev/linux"}"
export GH_TOKEN="${GH_TOKEN:-}"
export GH_COOLDOWN="${GH_COOLDOWN:-10}"
export COMMITTER_NAME="${COMMITTER_NAME:-}"
export COMMITTER_USERNAME="${COMMITTER_USERNAME:-"TheBusyDev"}"
export COMMITTER_EMAIL="${COMMITTER_EMAIL:-}"
export PR_LABEL="${PR_LABEL:-"autobump"}"
export GITHUB_OUTPUT="${GITHUB_OUTPUT:-"github_output.log"}"

export HOMEBREW_GITHUB_API_TOKEN="${GH_TOKEN}"
export HOMEBREW_GIT_COMMITTER_NAME="${COMMITTER_NAME}"
export HOMEBREW_GIT_COMMITTER_EMAIL="${COMMITTER_EMAIL}"
export HOMEBREW_BUMP_DRYRUN_PR_NUMBER="${HOMEBREW_BUMP_DRYRUN_PR_NUMBER:-}"

# Match `version "<version>"` entries in `.rb` files.
# shellcheck disable=SC2034
declare -rA VERSION_REGEX=(
  ["key"]='version'
  ["value"]='".+"'
)

# Match `sha256` entries in `.rb` files:
#  sha256 "<sha256-signature>"
#  sha256 arm64_linux:  "<sha256-signature>"
#         x86_64_linux: "<sha256-signature>"
# shellcheck disable=SC2034
declare -rA SHA256_REGEX=(
  ["key"]='sha256'
  ["value"]='("[[:xdigit:]]{64}"|arm64_linux:[[:blank:]]*"[[:xdigit:]]{64}",\n[[:blank:]]*x86_64_linux:[[:blank:]]*"[[:xdigit:]]{64}")'
)

# Match `depends_on :linux` stanzas in `.rb` files.
# shellcheck disable=SC2034
declare -rA DEPENDS_ON_LINUX_REGEX=(
  ["key"]='depends_on'
  ["value"]=':linux'
)

# Match `depends_on :macos` stanzas in `.rb` files.
# shellcheck disable=SC2034
declare -rA DEPENDS_ON_MACOS_REGEX=(
  ["key"]='depends_on'
  ["value"]=':?macos(:[[:blank:]]+:[[:lower:]]+)?'
)

# Global variable for internal use only. It contains an associative array with
# all the changes from all the PRs.
declare -A __ALL_PR_CHANGES__

# Change directory to the repository root.
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"/.. || exit 1

# Check if `brew` is installed.
if ! command -v "brew" > /dev/null 2>&1
then
  echo "::error::Missing dependency: \`brew\`." \
    "Visit https://brew.sh/ and install it! Cheers!" >&2
  exit 1
fi

# Check if the dependencies required in this repository command can be executed.
mapfile -t deps < .deps

for dep in "${deps[@]}"
do
  if ! command -v "${dep}" > /dev/null 2>&1
  then
    formula="$(brew which-formula "${dep}" || true)"
    error_msg="::error::Missing dependency: \`${dep}\`."

    if [[ -n "${formula}" ]]
    then
      error_msg+=" Please, install it by running \`brew install ${formula}\`"
      error_msg+=" and ensure it is added to your \`PATH\`."
    fi

    echo "${error_msg}" >&2
    exit 1
  fi
done

unset deps dep formula error_msg
