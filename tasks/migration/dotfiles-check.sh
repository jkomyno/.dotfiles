#!/usr/bin/env bash

#MISE description="Validate repository mise dotfiles against a temporary HOME"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec "${MISE_PROJECT_ROOT}/scripts/dotfiles/mise-dotfiles-check.sh" "$@"
