#!/bin/bash
# Set of functions used to execute the other scripts.
#

# Include guard.
[[ -v __FUNCTIONS_SH ]] && return 0
readonly __FUNCTIONS_SH=1

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh

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
function _get_formulae_or_casks_from_tap()
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
function get_formulae_from_tap()
{
  _get_formulae_or_casks_from_tap "formulae"
}

# Get all the casks from a given tap.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#
# Output:
# Writes a newline-separated list of casks to stdout.
#
function get_casks_from_tap()
{
  _get_formulae_or_casks_from_tap "casks"
}

# Bump a formula/cask, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `BUMP_PR_LABEL`: Pull request label (possibly empty).
# - `BUMP_DRYRUN_PR_NUMBER`: Enable dry-runs for `brew bump`. Specify the dummy
#                            PR number.
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
  readonly tmp_file
  trap "rm -f '${tmp_file}' 2>/dev/null" RETURN EXIT

  if [[ -z "${BUMP_DRYRUN_PR_NUMBER}" ]]
  then
    # Perform `brew bump`.
    brew bump "$1" --"$2" --full-name --open-pr --no-fork 2>&1 \
      | tee "${tmp_file}" >&2 \
      || {
        git reset --hard >&2 # Reset changed files.
        return 1
      }
  else
    # Dry-run for `brew bump`.
    echo "::warning::Dry-runs for \`brew bump\` are enabled." \
      "No action is performed." >&2

    if [[ ! "${BUMP_DRYRUN_PR_NUMBER}" =~ ^[[:digit:]]+$ ]]
    then
      echo "::error::\`BUMP_DRYRUN_PR_NUMBER\` should be a valid" \
        "PR number." >&2
      exit 1
    fi

    echo "https://github.com/DummyDev/DummyRepo/pull/${BUMP_DRYRUN_PR_NUMBER}" \
      > "${tmp_file}"
  fi

  # Retrieve PR number from log file.
  pr_url="$(
    grep -oE "^https://github\.com/[^/]+/[^/]+/pull/[[:digit:]]+$" "${tmp_file}" \
      | tail -n1 \
      || true
  )"
  pr_nr="${pr_url##*/}"

  if [[ -z "${BUMP_DRYRUN_PR_NUMBER}" && -n "${pr_nr}" ]]
  then
    # Update PR label.
    sleep "${GH_COOLDOWN}"
    gh pr edit "${pr_nr}" --add-label "${BUMP_PR_LABEL}" >&2
  fi

  echo "${pr_nr}"
}

# Bump a formula, creating a new pull request with the selected label.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_COOLDOWN`: Delay before retrieving info with `gh` (seconds).
# - `BUMP_PR_LABEL`: Pull request label (possibly empty).
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
# - `BUMP_PR_LABEL`: Pull request label (possibly empty).
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

# Obtain all the file additions/deletions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
# 3. Literal string: "+" (to retrieve additions) or "-" (to retrieve deletions).
#
# Output:
# Writes additions/deletions for the specific file to stdout.
#
function _get_pr_additions_or_deletions()
{
  # Fetch all the changes in the PR (if not already fetched).
  if [[ ! -v __ALL_PR_CHANGES__["$1"] ]]
  then
    __ALL_PR_CHANGES__["$1"]="$(gh pr diff "${pr_nr}")"
  fi

  # Retrieve the changes in the file (if not already retrieved).
  if [[ ! -v __ALL_PR_CHANGES__["$1.$2"] ]]
  then
    __ALL_PR_CHANGES__["$1.$2"]="$(
      echo "${__ALL_PR_CHANGES__["$1"]}" \
        | FILE="$2" awk '
            BEGIN {
              file = ENVIRON["FILE"]
              prefix = "diff --git a/" file " "
              suffix = " b/" file
            }
            /^diff --git / {
              inhunk = 0
              is_file = (substr($0, 1, length(prefix)) == prefix) || (substr($0, length($0) - length(suffix) + 1) == suffix)
              next
            }
            /^@@/ {
              inhunk = 1
              next
            }
            is_file && inhunk && /^[+-]/ {
              print $0
            }
          '
    )"
  fi

  # Filter the additions/deletions (if not already filtered).
  if [[ ! -v __ALL_PR_CHANGES__["$1.$2.$3"] ]]
  then
    __ALL_PR_CHANGES__["$1.$2.$3"]="$(
      echo "${__ALL_PR_CHANGES__["$1.$2"]}" | sed -ne "s/^$3//p"
    )"
  fi

  echo "${__ALL_PR_CHANGES__["$1.$2.$3"]}"
}

# Obtain all the file additions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
#
# Output:
# Writes additions for the specific file to stdout.
#
function get_pr_additions()
{
  _get_pr_additions_or_deletions "$1" "$2" "+"
}

# Obtain all the file deletions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
#
# Output:
# Writes deletions for the specific file to stdout.
#
function get_pr_deletions()
{
  _get_pr_additions_or_deletions "$1" "$2" "-"
}

# Obtain all the file unauthorized additions/deletions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
# 3. Literal string: "+" (to retrieve additions) or "-" (to retrieve deletions).
#
# Output:
# Writes unauthorized additions/deletions for the specific file to stdout.
#
function _get_pr_unauthorized_additions_or_deletions()
{
  _get_pr_additions_or_deletions "$1" "$2" "$3" \
    | perl -0777 -pe "s/$(_get_rb_entry_regex VERSION_REGEX)//gm" \
    | perl -0777 -pe "s/$(_get_rb_entry_regex SHA256_REGEX)//gm"
}

# Obtain all the file unauthorized additions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
#
# Output:
# Writes unauthorized additions for the specific file to stdout.
#
function get_pr_unauthorized_additions()
{
  _get_pr_unauthorized_additions_or_deletions "$1" "$2" "+"
}

# Obtain all the file unauthorized deletions from a pull request.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. The number of the pull request.
# 2. The filepath.
#
# Output:
# Writes unauthorized deletions for the specific file to stdout.
#
function get_pr_unauthorized_deletions()
{
  _get_pr_unauthorized_additions_or_deletions "$1" "$2" "-"
}

# Print the input additions/deletions, adding a leading "+"/"-" accordingly.
#
# Input:
# 1. Newline-separated string, containing the additions/deletions.
# 2. Literal string: "+" (to retrieve additions) or "-" (to retrieve deletions).
#
# Output:
# Writes additions/deletions to stdout, adding a leading "+"/"-" accordingly.
#
function _echo_pr_additions_or_deletions()
{
  # shellcheck disable=SC2001
  echo "$1" | sed -e "s/^/$2/"
}

# Print the input additions, adding a leading "+".
#
# Input:
# 1. Newline-separated string, containing the additions.
#
# Output:
# Writes additions to stdout, adding a leading "+".
#
function echo_pr_additions()
{
  _echo_pr_additions_or_deletions "$1" "+"
}

# Print the input deletions, adding a leading "-".
#
# Input:
# 1. Newline-separated string, containing the deletions.
#
# Output:
# Writes deletions to stdout, adding a leading "-".
#
function echo_pr_deletions()
{
  _echo_pr_additions_or_deletions "$1" "-"
}

# Get the number of occurrences in a file using Perl.
#
# Input:
# 1. The filepath.
# 2. The regex expression.
#
# Output:
# Writes the number of occurrences to stdout.
#
function _get_n_occurrences()
{
  n=$(REGEX="$2" perl -0777 -ne '$n++ while /$ENV{REGEX}/gm; print "$n\n"' "$1")
  echo "${n:-0}"
}

# Get the regular expression of the key defined in the input associative array.
#
# Input:
# 1. The regex entry, passed as an associative array with "key" and "value" keys.
#
# Output:
# Writes the complete regular expression of the key to stdout.
#
function _get_rb_key_regex()
{
  local -n __regex__="$1"
  printf '^[[:blank:]]*%s\\b' "${__regex__["key"]}"
}

# Get the regular expression of the entry defined in the input associative array.
#
# Input:
# 1. The regex entry, passed as an associative array with "key" and "value" keys.
#
# Output:
# Writes the complete regular expression of the entry to stdout.
#
function _get_rb_entry_regex()
{
  local -n ___regex___="$1"
  printf '%s[[:blank:]]+%s[[:blank:]]*(#[^\\n]*)?$' \
    "$(_get_rb_key_regex ___regex___)" \
    "${___regex___["value"]}"
}

# Check if the provided entry appears in the `*.rb` file.
#
# Input:
# 1. The `*.rb` filepath.
# 2. The regex entry, passed as an associative array with "key" and "value" keys.
#
# Output:
# Writes the number of found entries and the number of valid entries to stdout
# (separated by a whitespace).
#
function _check_rb_entry()
{
  local -n ____regex____="$2"
  local key_regex entry_regex n_found n_valid

  if [[ ! -f "$1" ]]
  then
    echo false
    return 1
  fi

  key_regex="$(_get_rb_key_regex ____regex____)"
  entry_regex="$(_get_rb_entry_regex ____regex____)"

  n_found=$(_get_n_occurrences "$1" "${key_regex}")
  n_valid=$(_get_n_occurrences "$1" "${entry_regex}")

  echo "${n_found} ${n_valid}"
}

# Check if the format of the version entry is correct in the `*.rb` file.
#
# Input:
# 1. The `*.rb` filepath.
#
# Output:
# Writes `true` if the version entry format is correct. `false` otherwise.
#
function check_rb_version()
{
  read -r n_found n_valid < <(_check_rb_entry "$1" VERSION_REGEX)
  ((n_found == n_valid)) && echo true || echo false
}

# Check if the format of the sha256 entry is correct in the `*.rb` file.
#
# Input:
# 1. The `*.rb` filepath.
#
# Output:
# Writes `true` if the sha256 entry appears at least once and its format is
# correct. `false` otherwise.
#
function check_rb_sha256()
{
  read -r n_found n_valid < <(_check_rb_entry "$1" SHA256_REGEX)
  ((n_found > 0 && n_found == n_valid)) && echo true || echo false
}

# Check if the formula/cask defined by the `*.rb` file depends on Linux.
#
# Input:
# 1. The `*.rb` filepath.
#
# Output:
# Writes `true` if the formula/cask explicitly depends on Linux.
# `false` otherwise.
#
function check_rb_depends_on_linux()
{
  read -r n_found n_valid < <(_check_rb_entry "$1" DEPENDS_ON_LINUX_REGEX)
  ((n_valid > 0)) && echo true || echo false
}

# Check if the formula/cask defined by the `*.rb` file depends on MacOS.
#
# Input:
# 1. The `*.rb` filepath.
#
# Output:
# Writes `true` if the formula/cask explicitly depends on MacOS.
# `false` otherwise.
#
function check_rb_depends_on_macos()
{
  read -r n_found n_valid < <(_check_rb_entry "$1" DEPENDS_ON_MACOS_REGEX)
  ((n_valid > 0)) && echo true || echo false
}
