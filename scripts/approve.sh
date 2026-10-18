#!/bin/bash
# Auto-approve some pull requests with certain criteria.
#
# Environment variables:
# - `GH_TOKEN`: Token used for authentication in `gh`.
# - `GH_APPROVE_DRYRUN`: If set, only check pull requests without approving.
#
# Input:
# 1. Colon-separated list of pull request numbers.
#
# TODO: add criteria list to README.md

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
source ./scripts/__functions.sh

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

    # Get changes from the PR.
    dels="$(get_pr_deletions "${pr_nr}" "${file}")"
    adds="$(get_pr_additions "${pr_nr}" "${file}")"

    if [[ -n "${dels}" ]] || [[ -n "${adds}" ]]
    then
      echo "Changes w.r.t. base branch:"
      echo_pr_deletions "${dels}"
      echo_pr_additions "${adds}"

      # Find unauthorized changes.
      unauthorized_dels="$(get_pr_unauthorized_deletions "${pr_nr}" "${file}")"
      unauthorized_adds="$(get_pr_unauthorized_additions "${pr_nr}" "${file}")"

      if [[ -n "${unauthorized_dels}" ]] || [[ -n "${unauthorized_adds}" ]]
      then
        echo "::error file=${file}::Unauthorized changes found:" >&2
        echo_pr_deletions "${unauthorized_dels}" >&2
        echo_pr_additions "${unauthorized_adds}" >&2
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
  elif [[ -z "${GH_APPROVE_DRYRUN}" ]]
  then
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
