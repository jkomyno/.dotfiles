#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_ROOT="${DOTFILES:-$(cd -- "${SCRIPT_DIR}/../../.." && pwd -P)}"
readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"

log() { printf '==> %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

main() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  if [[ "${DOTFILES_SKIP_LOGIN_SHELL:-}" == "1" ]]; then
    log "Skipping login shell change (DOTFILES_SKIP_LOGIN_SHELL=1)"
    return 0
  fi

  [[ -x /usr/bin/zsh ]] || die "/usr/bin/zsh is missing; run the Linux package step first"
  [[ -x "${MISE_BIN}" ]] || die "mise is missing: ${MISE_BIN}"
  MISE_AUTO_ENV=true \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap user apply --yes "$@"
}

main "$@"
