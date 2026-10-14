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
mapfile -t formula_rb_files < <(formula_rb_files)
mapfile -t cask_rb_files < <(cask_rb_files)

# Check formulae.
echo "==> Checking target OS of formulae..."

for file in "${formula_rb_files[@]}"
do
  depends_on_linux="$(depends_on_linux "${file}")"
  depends_on_macos="$(depends_on_macos "${file}")"

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
echo "==> Checking target OS of casks..."

for file in "${cask_rb_files[@]}"
do
  depends_on_linux="$(depends_on_linux "${file}")"
  depends_on_macos="$(depends_on_macos "${file}")"

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

${linux_only} || exit 1 # Abort test.
exit 0
