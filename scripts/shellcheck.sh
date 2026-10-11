#!/bin/bash
# Run `shellcheck` and apply changes if `--apply` flag is passed.

source "$(dirname "$0")"/_env.sh
source "$(dirname "$0")"/_functions.sh

if [[ "$1" == "--apply" ]]; then
  shellcheck --rcfile=".shellcheckrc" --format=diff scripts/*.sh | git apply
else
  shellcheck --rcfile=".shellcheckrc" scripts/*.sh
fi
