#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly NANOBREW_BIN_DIR="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}"
readonly NANOBREW_FORMULAE_BUNDLE_NAME="nanobrew-formulae.Brewfile"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

script_dir() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P
}

nanobrew_command() {
  export PATH="${NANOBREW_BIN_DIR}:${PATH}"

  if command -v nb >/dev/null 2>&1; then
    command -v nb
    return
  fi

  die "nanobrew is not installed; run install/macos/common/nanobrew.sh first"
}

bundle_file() {
  if [[ -n "${NANOBREW_FORMULAE_BUNDLE:-}" ]]; then
    printf '%s\n' "${NANOBREW_FORMULAE_BUNDLE}"
    return
  fi

  printf '%s/%s\n' "$(script_dir)" "${NANOBREW_FORMULAE_BUNDLE_NAME}"
}

install_nanobrew_formulae() {
  local nb_cmd
  local bundle
  nb_cmd="$(nanobrew_command)"
  bundle="$(bundle_file)"

  [[ -r "${bundle}" ]] || die "nanobrew formula bundle not found: ${bundle}"

  log "Installing nanobrew formula bundle"
  "${nb_cmd}" bundle install "${bundle}"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  install_nanobrew_formulae
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
