#!/bin/bash
# Run `shellcheck` and apply changes if `--apply` flag is passed.

cd "$(dirname "$0")"/.. || exit 1

if [[ "$1" == "--apply" ]]; then
  shellcheck --rcfile=".shellcheckrc" --format=diff scripts/*.sh | git apply
else
  shellcheck --rcfile=".shellcheckrc" scripts/*.sh
fi
