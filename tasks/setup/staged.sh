#!/usr/bin/env bash
#MISE description="Run staged setup tasks in blank-machine order"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/scripts/dotfiles/mise-setup-staged.sh" "$@"
