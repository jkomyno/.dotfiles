#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly NANOBREW_BIN_DIR="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}"
readonly NANOBREW_CASKS_BUNDLE_NAME="nanobrew-casks.Brewfile"

cleanup_files=()

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ ${#cleanup_files[@]} -gt 0 ]]; then
    rm -f "${cleanup_files[@]}"
  fi
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
  if [[ -n "${DOTFILES_NANOBREW_CASKS_BUNDLE_CONTENT:-}" ]]; then
    local tmp_bundle
    tmp_bundle="$(mktemp)"
    cleanup_files+=("${tmp_bundle}")
    printf '%s\n' "${DOTFILES_NANOBREW_CASKS_BUNDLE_CONTENT}" >"${tmp_bundle}"
    printf '%s\n' "${tmp_bundle}"
    return
  fi

  if [[ -n "${NANOBREW_CASKS_BUNDLE:-}" ]]; then
    printf '%s\n' "${NANOBREW_CASKS_BUNDLE}"
    return
  fi

  printf '%s/%s\n' "$(script_dir)" "${NANOBREW_CASKS_BUNDLE_NAME}"
}

install_nanobrew_casks() {
  local nb_cmd
  local bundle
  nb_cmd="$(nanobrew_command)"
  bundle="$(bundle_file)"

  [[ -r "${bundle}" ]] || die "nanobrew cask bundle not found: ${bundle}"

  log "Installing nanobrew cask bundle"
  "${nb_cmd}" bundle install "${bundle}"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  trap cleanup EXIT
  install_nanobrew_casks
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
