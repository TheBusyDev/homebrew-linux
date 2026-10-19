#!/bin/bash
# Install `brew` dependencies from `.deps` file.
#

set -euo pipefail

mapfile -t deps < "$(dirname -- "${BASH_SOURCE[0]}")"/../.deps
all_installed=true

for dep in "${deps[@]}"
do
  formula="$(brew which-formula "${dep}")" \
    && brew install --formula -y "${formula}" \
    || {
      echo "::error::Cannot install dependency \`${dep}\`." >&2
      all_installed=false
    }
done

${all_installed} || exit 1

cat << EOMSG

Installed ${#deps[@]} dependencies!
EOMSG

exit 0
