#!/bin/bash
# Install `brew` dependencies from `.dependencies` file.
#

source "$(dirname "$0")"/_env.sh
mapfile -t deps < .dependencies

for dep in "${deps[@]}"
do
  formula="$(brew which-formula "${dep}")"
  brew install --formula "${formula}"
done

exit 0
