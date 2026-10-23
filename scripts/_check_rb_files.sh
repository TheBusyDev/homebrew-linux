#!/bin/bash
# Perform some checks given in REGEX format on `.rb` files in this repository.
#

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
source ./scripts/__functions.sh

# Useful variables.
success=true # Have all the checks passed successfully?
mapfile -t rb_files < <(find ./Formula ./Casks -name "*.rb" -type f)
echo "==> Checking formula/cask \`.rb\` files..."

for rb_file in "${rb_files[@]}"
do
  version_correct="$(check_rb_version "${rb_file}")"
  sha256_correct="$(check_rb_sha256 "${rb_file}")"
  depends_on_linux="$(check_rb_depends_on_linux "${rb_file}")"
  depends_on_macos="$(check_rb_depends_on_macos "${rb_file}")"

  if ! ${version_correct}
  then
    cat << EOMSG >&2

::error file=${rb_file}::\`version\` entry is provided in the wrong format.
Accepted style for this repository:
  version "1.0.0.build" # i.e. between double quotes!
EOMSG
    success=false
  fi

  if ! ${sha256_correct}
  then
    cat << EOMSG >&2

::error file=${rb_file}::\`sha256\` entry is provided in the wrong format.
Below a list of accepted styles for this repository:
  1. sha256 "<sha256-signature>"
  2. sha256 arm64_linux:  "<sha256-signature>",
            x86_64_linux: "<sha256-signature>"

Examples of forbidden styles:
  1. sha256 arm: "<sha256-signature>" # i.e. without \`_linux\` suffix.
  2. sha256 arm64_linux: "<sha256-signature>"
     sha256 x86_64_linux: "<sha256-signature>"
EOMSG
    success=false
  fi

  if ! ${depends_on_linux}
  then
    cat << EOMSG >&2

::error file=${rb_file}::Linux is not the target OS for this \`.rb\` file. \
Add \`depends_on :linux\` stanza.
EOMSG
    success=false
  fi

  if ${depends_on_macos}
  then
    cat << EOMSG >&2

::error file=${rb_file}::This repository hosts Linux formulae/casks only. \
Remove \`depends_on :macos\` stanza.
EOMSG
    success=false
  fi
done

${success} || exit 1 # Abort test.

cat << EOMSG

No offense found in ${#rb_files[@]} \`.rb\` files.
EOMSG

exit 0
