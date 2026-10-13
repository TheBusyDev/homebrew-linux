#!/bin/bash
# Install `brew` dependencies from `.dependencies` file.
#

mapfile -t deps < "$(dirname "$0")"/../.dependencies

for dep in "${deps[@]}"
do
  # shellcheck disable=SC2015
  formula="$(brew which-formula "${dep}")" \
    && brew install --formula "${formula}" \
    || {
      echo "::error::Cannot install dependency \`${dep}\`." >&2
      exit 1
    }
done

exit 0
