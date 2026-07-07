#!/usr/bin/env bash
#MISE depends=["install:macos:nanobrew-casks"]
#MISE description="Install the Ghostty terminfo entry for incoming SSH sessions"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/macos/common/ghostty-terminfo.sh" "$@"
