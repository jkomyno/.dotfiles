#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly NANOBREW_INSTALL_URL="${NANOBREW_INSTALL_URL:-https://nanobrew.trilok.ai/install}"
readonly NANOBREW_BIN_DIR="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

install_nanobrew() {
  export PATH="${NANOBREW_BIN_DIR}:${PATH}"

  if command -v nb >/dev/null 2>&1; then
    log "nanobrew already installed"
    return
  fi

  log "Installing nanobrew"
  local installer_home
  local installer_script
  installer_home="$(mktemp -d)"
  installer_script="$(mktemp)"

  if ! curl -fsSL "${NANOBREW_INSTALL_URL}" -o "${installer_script}"; then
    rm -rf "${installer_home}" "${installer_script}"
    die "failed to download nanobrew installer"
  fi

  # The installer appends PATH lines to $HOME/.zshrc. Use a temporary HOME so
  # the managed zprofile remains the only place that owns nanobrew PATH setup.
  if ! HOME="${installer_home}" bash "${installer_script}"; then
    rm -rf "${installer_home}" "${installer_script}"
    die "nanobrew installer failed"
  fi
  rm -rf "${installer_home}" "${installer_script}"

  command -v nb >/dev/null 2>&1 || die "nanobrew install finished, but nb is still unavailable"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  install_nanobrew
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
