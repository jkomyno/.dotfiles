#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly DEFAULT_MISE_BOOTSTRAP_VERSION="v2026.6.2"
readonly MISE_BOOTSTRAP_VERSION="${MISE_BOOTSTRAP_VERSION:-${DEFAULT_MISE_BOOTSTRAP_VERSION}}"
readonly MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
readonly MISE_INSTALLER_URL="https://raw.githubusercontent.com/jdx/mise/refs/tags/${MISE_BOOTSTRAP_VERSION}/packaging/standalone/install.envsubst"
readonly DEFAULT_MISE_MINIMUM_RELEASE_AGE="${MISE_MINIMUM_RELEASE_AGE:-7d}"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
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
    MISE_VERSION="${MISE_BOOTSTRAP_VERSION}" MISE_INSTALL_PATH="${MISE_INSTALL_PATH}" sh
}

install_configured_tools() {
  local args=()

  if "${MISE_INSTALL_PATH}" install --help | grep -q -- '--minimum-release-age'; then
    args=(--yes --minimum-release-age "${DEFAULT_MISE_MINIMUM_RELEASE_AGE}")
  else
    args=(--yes --before "${DEFAULT_MISE_MINIMUM_RELEASE_AGE}")
  fi

  log "Installing mise tools"
  PATH="$(dirname "${MISE_INSTALL_PATH}"):${PATH}" \
    "${MISE_INSTALL_PATH}" install "${args[@]}"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  install_mise
  install_configured_tools
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
