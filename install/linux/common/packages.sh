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

check_distribution() {
  [[ -r /etc/os-release ]] || die "cannot identify Linux distribution: /etc/os-release is missing"
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}:${VERSION_ID:-}" in
    debian:12 | ubuntu:24.04) return 0 ;;
    *) die "supported Linux distributions are Debian 12 and Ubuntu 24.04 (found ${ID:-unknown} ${VERSION_ID:-unknown})" ;;
  esac
}

main() {
  [[ "$(uname -s)" == "Linux" ]] || return 0
  if [[ "${DOTFILES_SKIP_LINUX_PACKAGES:-}" == "1" ]]; then
    log "Skipping Linux packages (DOTFILES_SKIP_LINUX_PACKAGES=1)"
    return 0
  fi

  check_distribution
  [[ -x "${MISE_BIN}" ]] || die "mise is missing: ${MISE_BIN}"
  MISE_AUTO_ENV=true \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap packages apply --manager apt --yes "$@"
}

main "$@"
