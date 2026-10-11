#!/bin/bash
# Set of functions used to execute the other scripts.

# Obtain the number of the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `COMMITTER_USERNAME`: The username of the committer.
#
# Input:
# 1. Pull request label (possibly empty).
#
# Output:
# Writes the number of the pull request to stdout.
#
function get_latest_pr_number() {
  sleep 6 # Cooldown to detect the latest PR correctly.
  gh pr list --author "$COMMITTER_USERNAME" --label "$1" --limit 1 \
    --json number | jq ".[0].number"
}

# Obtain a certain property of the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The key of the PR property.
#
# Output:
# Writes property of pull request to stdout.
#
function _get_pr_property() {
  gh pr view "$1" --json "$2" | jq -r ".$2"
}

# Obtain branch of the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
#
# Output:
# Writes branch of pull request to stdout.
#
function get_pr_branch() {
  _get_pr_property "$1" "headRefName"
}

# Obtain state of the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
#
# Output:
# Writes state of pull request to stdout.
#
function get_pr_state() {
  _get_pr_property "$1" "state" | tr "[:upper:]" "[:lower:]"
}

# Obtain URL of the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
#
# Output:
# Writes URL of pull request to stdout.
#
function get_pr_url() {
  _get_pr_property "$1" "url"
}

# Obtain all the files modified in the latest pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
#
# Output:
# Writes a newline-separated list of filepaths to stdout.
#
function get_pr_filepaths() {
  _get_pr_property "$1" "files" | jq -r ".[].path"
}

# Get all the formulae/casks from a given tap.
#
# Input:
# 1. The name of the tap.
# 2. Literal string: "formulae" or "casks".
#
# Output:
# Writes a newline-separated list to stdout.
#
function _formulae_or_casks_from_tap() {
  local array_name

  case "$2" in
    casks)
      array_name="cask_tokens"
      ;;
    *)
      array_name="formula_names"
      ;;
  esac

  brew tap-info "$1" --json=v1 | jq -r ".[].${array_name}[]"
}

# Get all the formulae from a given tap.
#
# Input:
# 1. The name of the tap.
#
# Output:
# Writes a newline-separated list of formulae to stdout.
#
function formulae_from_tap() {
  _formulae_or_casks_from_tap "$1" "formulae"
}

# Get all the casks from a given tap.
#
# Input:
# 1. The name of the tap.
#
# Output:
# Writes a newline-separated list of casks to stdout.
#
function casks_from_tap() {
  _formulae_or_casks_from_tap "$1" "casks"
}

# Bump a formula/cask, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
function _brew_bump_formula_or_cask() {
  brew bump "$1" --"$2" --full-name --open-pr --no-fork
  gh pr edit "$(get_latest_pr_number "")" --add-label "$PR_LABEL"
}

# Bump a formula, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the formula.
#
function brew_bump_formula() {
  _brew_bump_formula_or_cask "$1" "formula"
}

# Bump a cask, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the cask.
#
function brew_bump_cask() {
  _brew_bump_formula_or_cask "$1" "cask"
}

# Retrieve JSON file from the selected formula/cask.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
# Output:
# Writes JSON file to stdout.
#
function _json_from_formula_or_cask() {
  local array_name

  case "$2" in
    cask)
      array_name="casks"
      ;;
    *)
      array_name="formulae"
      ;;
  esac

  brew info "$1" --"$2" --json=v2 | jq -r ".${array_name}[0]"
}

# Retrieve ruby source file from the selected formula/cask.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
# Output:
# Writes ruby source filepath to stdout.
#
function _formula_or_cask_source_file() {
  _json_from_formula_or_cask "$1" "$2" | jq -r ".ruby_source_path"
}

# Retrieve ruby source file from the selected formula.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Writes ruby source filepath to stdout.
#
function formula_source_file() {
  _formula_or_cask_source_file "$1" "formula"
}

# Retrieve ruby source file from the selected cask.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Writes ruby source filepath to stdout.
#
function cask_source_file() {
  _formula_or_cask_source_file "$1" "cask"
}

# Check if the selected formula/cask depends on Linux/MacOS.
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
# 3. Literal string: "linux" or "macos".
#
# Output:
# Write "true" to stdout if depending on Linux/MacOS. "false" otherwise.
#
function _formula_or_cask_depends_on_linux_or_macos() {
  local depends_on
  depends_on="$(_json_from_formula_or_cask "$1" "$2" | jq -r ".depends_on.$3")"

  if [[ "$depends_on" != "null" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

# Check if the selected formula depends on Linux.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Write "true" to stdout if depending on Linux. "false" otherwise.
#
function formula_depends_on_linux() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "formula" "linux"
}

# Check if the selected formula depends on MacOS.
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Write "true" to stdout if depending on MacOS. "false" otherwise.
#
function formula_depends_on_macos() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "formula" "macos"
}

# Check if the selected cask depends on Linux.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Write "true" to stdout if depending on Linux. "false" otherwise.
#
function cask_depends_on_linux() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "cask" "linux"
}

# Check if the selected cask depends on MacOS.
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Write "true" to stdout if depending on MacOS. "false" otherwise.
#
function cask_depends_on_macos() {
  _formula_or_cask_depends_on_linux_or_macos "$1" "cask" "macos"
}
