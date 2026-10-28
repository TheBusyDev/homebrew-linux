#!/bin/bash
# Automated tests for other scripts contained in this directory.
# Currently, automated tests are implemented for the following scripts:
# - scripts/bump.sh
# - scripts/approve.sh
#
# Environment variables:
# - `TAP_NAME`: The name of the tap to be updated.
# - `GH_TOKEN`: Token used for authentication in `gh`.
#

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
source ./scripts/__functions.sh

n_succeeded=0 # Number of succeeded tests.
n_failed=0    # Number of failed tests.

# Bump test.
# shellcheck disable=SC2329
function bump-test()
{
  local BUMP_DRYRUN_PR_NUMBER=1
  local GITHUB_OUTPUT="github_output.log"
  ./scripts/bump.sh > /dev/null
  cat "${GITHUB_OUTPUT}"
  rm "${GITHUB_OUTPUT}"
}

mapfile -t rb_files < <(find ./Formula ./Casks -name "*.rb" -type f)
expected_output="$(perl -e "print join(':', ('1') x ${#rb_files[@]})")"
expected_output="pr-numbers=${expected_output}"

run_automated_test bump-test "${expected_output}" \
  && ((++n_succeeded)) \
  || ((++n_failed))

# Approve test.
# shellcheck disable=SC2329
function approve-test()
{
  local GH_APPROVE_DRYRUN=1
  ./scripts/approve.sh "52:53:88" 2>&1 || true
}

expected_output="$(cat scripts/logs/approve_test.log)"

run_automated_test approve-test "${expected_output}" \
  && ((++n_succeeded)) \
  || ((++n_failed))

# Print message and exit.
cat << EOMSG

Number of succeeded tests: ${n_succeeded}.
Number of failed tests:    ${n_failed}.
EOMSG

((n_failed == 0)) || exit 1
exit 0
