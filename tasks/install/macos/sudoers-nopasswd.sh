#!/usr/bin/env bash
#MISE description="Enable passwordless sudo for the current user (opt-in via DOTFILES_ENABLE_NOPASSWD_SUDO)"

set -Eeuo pipefail

if [[ -z "${MISE_PROJECT_ROOT:-}" ]]; then
  printf 'error: MISE_PROJECT_ROOT is not set; run this via mise\n' >&2
  exit 1
fi

exec bash "${MISE_PROJECT_ROOT}/install/macos/common/sudoers-nopasswd.sh" "$@"
