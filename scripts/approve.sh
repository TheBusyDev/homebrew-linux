#!/bin/bash
# Auto-approve some pull requests with certain criteria.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
#
# Input:
# 1. Colon-separated list of pull request numbers.
#
# TODO: add criteria list to README.md

source "$(dirname "$0")"/__env.sh
source "$(dirname "$0")"/__functions.sh

# Check for every PR in `pr_numbers`.
: "${1:?You must provide a colon-separated list of pull request numbers\!}"
mapfile -d ":" -t pr_numbers < <(echo -n "$1")
failed_pr_urls="" # Newline-separated list of URLs for non-approved pull requests.
success=true      # Have all the approvals run successfully?

for pr_nr in "${pr_numbers[@]}"
do
  echo "==> Checking pull request #${pr_nr}..."

  if [[ ! "${pr_nr}" =~ ^[[:digit:]]+$ ]]
  then
    echo "::error::\"${pr_nr}\" is not a valid PR number." >&2
    success=false
    continue
  fi

  # Get relevant info from PR.
  pr_state="$(get_pr_state "${pr_nr}")"
  pr_url="$(get_pr_url "${pr_nr}")"

  # Start checks on the PR.
  safe_to_approve=true

  # Check the PR state.
  if [[ "${pr_state}" != "open" ]]
  then
    echo "::error::The pull request #${pr_nr} is not open." >&2
    safe_to_approve=false
  fi

  # Get the changed files and check them.
  mapfile -t pr_files < <(get_pr_filepaths "${pr_nr}")
  # Fetch all the changes in the PR.
  all_changes="$(gh pr diff "${pr_nr}" --color=never)"

  for file in "${pr_files[@]}"
  do
    echo "==> Checking file \`${file}\` from pull request #${pr_nr}..."

    # Check if not only formula/cask files are modified.
    if [[ ! "${file}" =~ ^(Formula|Casks)/.*\.rb$ ]]
    then
      echo "::error file=${file}::This PR does not modify \`.rb\` files only." >&2
      safe_to_approve=false
      continue
    fi

    # Check difference between files modified in PR and the ones on default branch.
    file_changes="$(
      echo "${all_changes}" \
        | FILE="${file}" awk '
          BEGIN { file = ENVIRON["FILE"]; prefix = "diff --git a/" file " "; suffix = " b/" file }
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
            print substr($0, 2)
          }
        '
    )"

    if [[ -n "${file_changes}" ]]
    then
      echo -e "Changes w.r.t. base branch:\n${file_changes}\n"

      unauthorized_changes="$(
        echo "${file_changes}" \
          | sed -zE "s/$(get_rb_entry_regex VERSION_REGEX)/\n/g" \
          | sed -zE "s/$(get_rb_entry_regex SHA256_REGEX)/\n/g"
      )"

      if [[ -n "${unauthorized_changes}" ]]
      then
        echo -e "::error file=${file}::Unauthorized changes found:" >&2
        echo -e "${unauthorized_changes}\n" >&2
        safe_to_approve=false
        continue
      fi
    fi
  done

  if ! ${safe_to_approve}
  then
    # Append the PR URL to the failed ones.
    failed_pr_urls+="\n${pr_url}"
    success=false
  else
    # Finally, approve the PR.
    echo "==> Approving pull request #${pr_nr}..."
    gh pr review "${pr_nr}" --approve
    gh pr merge "${pr_nr}" --merge --auto
  fi
done

failed_pr_urls="${failed_pr_urls%\\n}"
failed_pr_urls="${failed_pr_urls#\\n}"

if [[ -n "${failed_pr_urls}" ]]
then
  echo -e "\n::error::The following PRs require manual approval:" >&2
  echo -e "${failed_pr_urls}" >&2
fi

${success} || exit 1
exit 0
