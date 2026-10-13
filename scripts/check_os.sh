#!/bin/bash
# Check if all the formulae/casks from the provided tap are developed for Linux
# only.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

# Useful variables.
linux_only=true # Are all the formulae/taps developed for Linux only?

# Get formulae and casks from the tap.
mapfile -t formulae < <(formulae_from_tap)
mapfile -t casks < <(casks_from_tap)

# Check formulae.
echo "==> Checking formulae..."

for formula in "${formulae[@]}"
do
  file="$(formula_source_file "${formula}")"
  depends_on_linux="$(formula_depends_on_linux "${formula}")"
  depends_on_macos="$(formula_depends_on_macos "${formula}")"

  if ! ${depends_on_linux}
  then
    echo "::error file=${file}::Linux is not the target OS for this formula." \
      "Add \`depends_on :linux\` stanza." >&2
    linux_only=false
  fi

  if ${depends_on_macos}
  then
    echo "::error file=${file}::This repository hosts Linux formulae only." \
      "Cannot include formulae developed for MacOS." \
      "Remove \`depends_on :macos\` stanza." >&2
    linux_only=false
  fi
done

# Check casks.
echo "==> Checking casks..."

for cask in "${casks[@]}"
do
  file="$(cask_source_file "${cask}")"
  depends_on_linux="$(cask_depends_on_linux "${cask}")"
  depends_on_macos="$(cask_depends_on_macos "${cask}")"

  if ! ${depends_on_linux}
  then
    echo "::error file=${file}::Linux is not the target OS for this cask." \
      "Add \`depends_on :linux\` stanza." >&2
    linux_only=false
  fi

  if ${depends_on_macos}
  then
    echo "::error file=${file}::This repository hosts Linux casks only." \
      "Cannot include casks developed for MacOS." \
      "Remove \`depends_on :macos\` stanza." >&2
    linux_only=false
  fi
done

if ! ${linux_only}
then
  # Abort test.
  exit 1
fi

exit 0
