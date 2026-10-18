#!/bin/bash
# This script is used to check the style of the entire tap.
# The following checks are executed:
# - `brew style` and `brew audit` on all the formulae/casks;
# - `shellcheck` and `shfmt` on all the bash scripts;
# - check style of all the `.rb` source files.
#
# Possibly apply changes if `--fix` flag is enabled.
#
# Environment variables:
# - `TAP_NAME`: The name of the tap.
#

source -- "$(dirname -- "${BASH_SOURCE[0]}")"/__env.sh
source ./scripts/__functions.sh

arg="${1:-}"
mapfile -t formulae < <(get_formulae_from_tap)
mapfile -t casks < <(get_casks_from_tap)
mapfile -t scripts < <(find ./scripts -name "*.sh" -type f)
success=true # Is the style of the tap complaint?

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

if [[ "${arg}" == "--fix" ]]
then
  echo "==> Fixing style of formulae..."
  brew style --formulae --fix "${formulae[@]}"
  echo "==> Fixing style of casks..."
  brew style --casks --fix "${casks[@]}"
  echo "==> Fixing style of scripts..."
  shellcheck --rcfile=".shellcheckrc" --format=diff "${scripts[@]}" \
    | git apply --allow-empty
  ./scripts/_shfmt.sh --write "${scripts[@]}"

  exit 0
fi

echo "==> Checking style of formulae..."
brew style --formulae "${formulae[@]}" || success=false
echo "==> Checking style of casks..."
brew style --casks "${casks[@]}" || success=false
echo "==> Checking style of scripts..."
shellcheck --rcfile=".shellcheckrc" "${scripts[@]}" || success=false
./scripts/_shfmt.sh "${scripts[@]}" || success=false

echo "==> Auditing formulae..."
brew audit --formulae --strict "${formulae[@]}" || success=false
echo "==> Auditing casks..."
brew audit --casks --strict "${casks[@]}" || success=false

echo "==> Live-checking formulae..."
brew livecheck --formulae --debug "${formulae[@]}" || success=false
echo "==> Live-checking casks..."
brew livecheck --casks --debug "${casks[@]}" || success=false

./scripts/_check_rb_files.sh || success=false

if ! ${success}
then
  echo -e "\n\n::error::Some offenses found. You can try to correct them by" \
    "invoking: \`$0 --fix\`."
  exit 1
fi

cat << EOMSG


No offense found in:
- ${#formulae[@]} formulae;
- ${#casks[@]} casks;
- ${#scripts[@]} bash scripts.
EOMSG
exit 0
