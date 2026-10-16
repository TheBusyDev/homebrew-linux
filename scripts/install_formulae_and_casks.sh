#!/bin/bash
# Install all the formulae/casks from the given tap and test their installation.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
source ./scripts/__functions.sh

# Get formulae and casks from the tap.
mapfile -t formulae < <(get_formulae_from_tap)
mapfile -t casks < <(get_casks_from_tap)
success=true # Did all tests passed?

# Install and test.
echo "==> Installing and testing formulae..."
for formula in "${formulae[@]}"
do
  brew reinstall --formula -y "${formula}" \
    || {
      echo "::error::Cannot install formula \`${formula}\`." >&2
      success=false
    }
  brew test "${formula}" \
    || {
      echo "::error::Test failed for formula \`${formula}\`." >&2
      success=false
    }
done

echo "==> Installing casks..."
for cask in "${casks[@]}"
do
  brew reinstall --cask -y "${cask}" \
    || {
      echo "::error::Cannot install cask \`${cask}\`." >&2
      success=false
    }
done

${success} || exit 1

echo -e "\nInstalled ${#formulae[@]} formulae and ${#casks[@]} casks!"
exit 0
