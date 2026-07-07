#!/usr/bin/env bash
#MISE depends=["install:macos:nanobrew-formulae"]
#MISE description="Install the tailscaled system daemon and guide joining the tailnet"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/macos/common/tailscale.sh" "$@"
