#!/bin/bash
# Set of environment variable definitions.
# **WARNING:** When sourcing this file, current directory will be always moved
# to the repository root, as required by all the scripts in this repository.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `COMMITTER_NAME`: The name of the committer.
# - `COMMITTER_USERNAME`: The username of the committer.
# - `COMMITTER_EMAIL`: The email address of the committer.
# - `PR_LABEL`: Label for the pull requests created by `brew bump`.
# - `GITHUB_OUTPUT`: Used to write output.
#

# Environment variables.
export GH_TOKEN="${GH_TOKEN:-}"
export COMMITTER_NAME="${COMMITTER_NAME:-}"
export COMMITTER_USERNAME="${COMMITTER_USERNAME:-}"
export COMMITTER_EMAIL="${COMMITTER_EMAIL:-}"
export PR_LABEL="${PR_LABEL:-}"
export GITHUB_OUTPUT="${GITHUB_OUTPUT:-"github_output.log"}"

export HOMEBREW_GITHUB_API_TOKEN="${GH_TOKEN}"
export HOMEBREW_GIT_COMMITTER_NAME="${COMMITTER_NAME}"
export HOMEBREW_GIT_COMMITTER_EMAIL="${COMMITTER_EMAIL}"

# Change directory to the repository root.
cd "$(dirname "$0")"/.. || exit 1
