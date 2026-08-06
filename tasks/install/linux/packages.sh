#!/usr/bin/env bash
#MISE description="Install Debian/Ubuntu OS prerequisites through mise"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/linux/common/packages.sh" "$@"
