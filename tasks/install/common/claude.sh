#!/usr/bin/env bash
#MISE description="Install the Claude Code CLI when it is missing"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/common/claude.sh" "$@"
