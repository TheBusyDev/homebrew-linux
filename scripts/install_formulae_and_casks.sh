#!/bin/bash
# Install all the formulae/casks from the given tap and test their installation.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

# Get formulae and casks from the tap.
mapfile -t formulae < <(formulae_from_tap)
mapfile -t casks < <(casks_from_tap)

# Install and test.
echo "==> Installing and testing formulae..."
for formula in "${formulae[@]}"
do
  brew reinstall --formula -y "${formula}"
  brew test "${formula}"
done

echo "==> Installing casks..."
for cask in "${casks[@]}"
do
  brew reinstall --cask -y "${cask}"
done

exit 0
