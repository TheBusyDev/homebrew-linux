#!/bin/bash
# Perform some checks given in REGEX format on `.rb` files in this repository.
#

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

# Useful variables.
success=true # Have all the checks passed successfully?
mapfile -t rb_files < <(find ./Formula ./Casks -name "*.rb" -type f)
echo "==> Checking formula/cask \`.rb\` files..."

for rb_file in "${rb_files[@]}"
do
  sha256_correct="$(is_rb_entry SHA256_REGEX "${rb_file}")"
  depends_on_linux="$(is_rb_entry DEPENDS_ON_LINUX_REGEX "${rb_file}")"
  depends_on_macos="$(is_rb_entry DEPENDS_ON_MACOS_REGEX "${rb_file}")"

  if ! ${sha256_correct}
  then
    cat << EOMSG >&2

::error file=${rb_file}::\`sha256\` entry is provided in the wrong format.
Below a list of accepted styles for this repository:
  sha256 "<sha256-signature>"
  sha256 arm64_linux: "<sha256-signature>"
  sha256 x86_64_linux: "<sha256-signature>"

Examples of forbidden styles:
  sha256 arm: "<sha256-signature>" # i.e. without \`_linux\` suffix.
  sha256 arm64_linux:  "<sha256-signature>",
         x86_64_linux: "<sha256-signature>" # i.e. multiline definition.
EOMSG
    success=false
  fi

  if ! ${depends_on_linux}
  then
    echo -e "\n::error file=${rb_file}::Linux is not the target OS for this \`.rb\` file." \
      "Add \`depends_on :linux\` stanza." >&2
    success=false
  fi

  if ${depends_on_macos}
  then
    echo -e "\n::error file=${rb_file}::This repository hosts Linux formulae/casks only." \
      "Cannot include formulae/casks developed for MacOS." \
      "Remove \`depends_on :macos\` stanza." >&2
    success=false
  fi
done

${success} || exit 1 # Abort test.

echo -e "\nNo offense found in ${#rb_files[@]} \`.rb\` files."
exit 0
