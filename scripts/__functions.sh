#!/bin/bash
# Set of functions used to execute the other scripts.
#

# Include guard.
[[ -n "${__FUNCTIONS_SH:-}" ]] && return 0
readonly __FUNCTIONS_SH=1

source "$(dirname "$0")"/__env.sh

# Obtain a certain property of a pull request.
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
function _get_pr_property()
{
  gh pr view "$1" --json "$2" | jq -r ".$2"
}

# Obtain state of a pull request.
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
function get_pr_state()
{
  _get_pr_property "$1" "state" | tr "[:upper:]" "[:lower:]"
}

# Obtain URL of a pull request.
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
function get_pr_url()
{
  _get_pr_property "$1" "url"
}

# Obtain all the files modified in a pull request.
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
function get_pr_filepaths()
{
  _get_pr_property "$1" "files" | jq -r ".[].path"
}

# Get all the formulae/casks from a given tap.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#
# Input:
# 1. Literal string: "formulae" or "casks".
#
# Output:
# Writes a newline-separated list to stdout.
#
function _formulae_or_casks_from_tap()
{
  local array_name

  case "$1" in
    casks)
      array_name="cask_tokens"
      ;;
    *)
      array_name="formula_names"
      ;;
  esac

  brew tap-info "${TAP_NAME}" --json=v1 | jq -r ".[].${array_name}[]"
}

# Get all the formulae from a given tap.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#
# Output:
# Writes a newline-separated list of formulae to stdout.
#
function formulae_from_tap()
{
  _formulae_or_casks_from_tap "formulae"
}

# Get all the casks from a given tap.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#
# Output:
# Writes a newline-separated list of casks to stdout.
#
function casks_from_tap()
{
  _formulae_or_casks_from_tap "casks"
}

# Bump a formula/cask, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the formula/cask.
# 2. Literal string: "formula" or "cask".
#
# Output:
# Writes the number of the newly created pull request to stdout (empty if no
# pull request has been created).
# Writes logging info from `brew bump` and `gh` to stderr.
#
function _brew_bump_formula_or_cask()
{
  local tmp_file pr_url pr_nr

  # Bump and save output to a temporary file.
  tmp_file="$(mktemp)"
  trap 'rm -f "${tmp_file}" 2>/dev/null' RETURN EXIT

  brew bump "$1" --"$2" --full-name --open-pr --no-fork 2>&1 \
    | tee "${tmp_file}" >&2 \
    || {
      git reset --hard >&2 # Reset changed files.
      return $?
    }

  # Retrieve PR number from log file.
  pr_url="$(echo "${tmp_file}" \
    | grep -oE "^https://github\.com/[^/]+/[^/]+/pull/[[:digit:]]+$" \
    | tail -n1 || true)"
  pr_nr="${pr_url##*/}"

  if [[ -n "${pr_nr}" ]]
  then
    # Update PR label.
    sleep "${GH_COOLDOWN}"
    gh pr edit "${pr_nr}" --add-label "${PR_LABEL}" >&2
  fi

  echo "${pr_nr}"
}

# Bump a formula, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the formula.
#
# Output:
# Writes the number of the newly created pull request to stdout (empty if no
# pull request has been created).
# Writes logging info from `brew bump` and `gh` to stderr.
#
function brew_bump_formula()
{
  _brew_bump_formula_or_cask "$1" "formula"
}

# Bump a cask, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `PR_LABEL`: Pull request label (possibly empty).
#
# Input:
# 1. The fully-qualified name of the cask.
#
# Output:
# Writes the number of the newly created pull request to stdout (empty if no
# pull request has been created).
# Writes logging info from `brew bump` and `gh` to stderr.
#
function brew_bump_cask()
{
  _brew_bump_formula_or_cask "$1" "cask"
}

# Get the regular expression defined in the input associative array.
#
# Input:
# 1. The regex entry, passed as an associative array with "key" and "value" keys.
#
# Output:
# Writes the complete regular expression of the entry to stdout.
#
function get_rb_entry_regex()
{
  local -n __regex__="$1"
  printf '\\n[[:blank:]]*%s[[:blank:]]+%s\\n' "${__regex__["key"]}" "${__regex__["value"]}"
}

# Check if the provided entry appears in the `*.rb` file
#
# Input:
# 1. The regex entry, passed as an associative array with "key" and "value" keys.
# 2. The `*.rb` filepath.
#
# Output:
# Writes `true` if "key" is found in the `*.rb` and its value matches "value".
# `false` otherwise.
#
function is_rb_entry()
{
  local -n ____regex____="$1"
  if [[ ! -f "$2" ]]
  then
    echo false
    return 1
  fi

  grep -zqP "$(get_rb_entry_regex ____regex____)" "$2" \
    && echo true \
    || echo false
}
