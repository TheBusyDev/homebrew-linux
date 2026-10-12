#!/bin/bash
# Run `shellcheck` and `shfmt` to check the syntax of bash scripts located in
# `./scripts/*.sh`.
# Possibly apply changes if `--fix` flag is enabled.

source "$(dirname "$0")"/_env.sh

shopt -s nullglob
files=(./scripts/*.sh)

if ((${#files[@]} == 0))
then
  echo "No bash script found". >&2
  exit 1
fi

if [[ "$1" == "--fix" ]]
then
  shellcheck --rcfile=".shellcheckrc" --format=diff "${files[@]}" \
    | git apply --allow-empty \
    && ./scripts/_shfmt.sh --write "${files[@]}" \
    || exit $?
else
  shellcheck --rcfile=".shellcheckrc" "${files[@]}" \
    && ./scripts/_shfmt.sh "${files[@]}" \
    || exit $?
fi
