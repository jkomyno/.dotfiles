#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_ROOT="${DOTFILES:-$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)}"
readonly DEFAULT_MISE_BOOTSTRAP_VERSION="v2026.11.8"
readonly MISE_BOOTSTRAP_VERSION="${MISE_BOOTSTRAP_VERSION:-${DEFAULT_MISE_BOOTSTRAP_VERSION}}"
readonly MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
readonly MISE_INSTALLER_URL="https://github.com/jdx/mise/releases/download/${MISE_BOOTSTRAP_VERSION}/install.sh"
install_tools="true"
dry_run="false"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: install/common/mise.sh [options]

Install the pinned standalone mise binary and, by default, the configured tools.

Options:
  --binary-only, --skip-tools  Install or update the mise binary only.
  --dry-run                    Preview configured tool installation.
  -h, --help                  Show this help.
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --binary-only | --skip-tools)
        install_tools="false"
        ;;
      --dry-run)
        dry_run="true"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
    shift
  done
}

installed_mise_version() {
  if [[ -x "${MISE_INSTALL_PATH}" ]]; then
    "${MISE_INSTALL_PATH}" --version 2>/dev/null | awk '{print $1}'
  fi
}

install_mise() {
  local wanted_version
  wanted_version="${MISE_BOOTSTRAP_VERSION#v}"

  if [[ "$(installed_mise_version || true)" == "${wanted_version}" ]]; then
    log "mise ${wanted_version} already installed"
    return
  fi

  log "Installing mise ${MISE_BOOTSTRAP_VERSION}"
  curl -fsSL "${MISE_INSTALLER_URL}" |
    env MISE_VERSION="${MISE_BOOTSTRAP_VERSION}" MISE_INSTALL_PATH="${MISE_INSTALL_PATH}" sh
}

install_configured_tools() {
  local sync=--sync
  if [[ "${dry_run}" == true ]]; then sync=--sync-check; fi
  env MISE_INSTALL_PATH="${MISE_INSTALL_PATH}" bash "${DOTFILES_ROOT}/scripts/dotfiles/versions.sh" "${sync}"
}

check_platform() {
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64 | Linux:x86_64 | Linux:aarch64 | Linux:arm64) return 0 ;;
    Darwin:*) die "only macOS arm64 is supported" ;;
    Linux:*) die "only Linux x64 and arm64 are supported" ;;
    *) die "unsupported platform: $(uname -s) $(uname -m)" ;;
  esac
}

main() {
  parse_args "$@"

  check_platform

  if [[ "${dry_run}" == "true" ]]; then
    [[ -x "${MISE_INSTALL_PATH}" ]] || die "mise is required for --dry-run: ${MISE_INSTALL_PATH}"
  else
    install_mise
  fi
  [[ "${install_tools}" == "true" ]] || return 0
  install_configured_tools
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
