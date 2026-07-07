#!/usr/bin/env bash
#MISE description="Enable native mac-to-mac Screen Sharing (opt-in; not run during staged setup)"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/macos/common/screen-sharing.sh" "$@"
