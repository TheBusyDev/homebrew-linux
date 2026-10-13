#!/bin/bash
# This script is used to check the style of the entire tap. It executes:
# - `brew style` and `brew audit` on all the formulae/casks;
# - `shellcheck` and `shfmt` on all the bash scripts.
#
# Possibly apply changes if `--fix` flag is enabled.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

mapfile -t formulae < <(formulae_from_tap)
mapfile -t casks < <(casks_from_tap)
mapfile -t scripts < <(find ./scripts -name "*.sh" -type f)

if ((${#formulae[@]} == 0))
then
  echo "::error::No formula found". >&2
  exit 1
fi

if ((${#casks[@]} == 0))
then
  echo "::error::No cask found". >&2
  exit 1
fi

if ((${#scripts[@]} == 0))
then
  echo "::error::No bash script found". >&2
  exit 1
fi

if [[ "$1" == "--fix" ]]
then
  echo "==> Fixing formulae..."
  brew style --formulae --fix "${formulae[@]}"
  echo "==> Fixing casks..."
  brew style --casks --fix "${casks[@]}"
  echo "==> Fixing scripts..."
  shellcheck --rcfile=".shellcheckrc" --format=diff "${scripts[@]}" \
    | git apply --allow-empty
  ./scripts/_shfmt.sh --write "${scripts[@]}"
else
  echo "==> Checking formulae..."
  brew style --formulae "${formulae[@]}"
  echo "==> Checking casks..."
  brew style --casks "${casks[@]}"
  echo "==> Checking scripts..."
  shellcheck --rcfile=".shellcheckrc" "${scripts[@]}"
  ./scripts/_shfmt.sh "${scripts[@]}"
fi

echo "==> Auditing formulae.."
brew audit --strict --formulae "${formulae[@]}"
echo "==> Auditing casks.."
brew audit --strict --casks "${casks[@]}"

exit 0
