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

bundle_cask_names() {
  # Extract cask names from a Brewfile-style bundle, preserving order.
  sed -nE 's/^[[:space:]]*cask[[:space:]]+"([^"]+)".*/\1/p' "$1"
}

install_nanobrew_casks() {
  local nb_cmd
  local bundle
  nb_cmd="$(nanobrew_command)"
  bundle="$(bundle_file)"

  [[ -r "${bundle}" ]] || die "nanobrew cask bundle not found: ${bundle}"

  log "Installing nanobrew cask bundle"
  if "${nb_cmd}" bundle install "${bundle}"; then
    return 0
  fi

  # A single failing cask aborts the whole bundle, which blocks every later
  # staged-setup step. Retry casks individually so one bad entry only affects
  # itself. Font casks are tolerated with a warning: nanobrew currently cannot
  # install variable-font releases whose filenames contain axis tags (for
  # example JetBrainsMono[wght].ttf) because it rejects '[' as a glob character
  # (error.UnsafePath); apps keep failing hard.
  log "Bundle install failed; retrying casks individually"
  local cask
  local -a failures=()
  while IFS= read -r cask; do
    [[ -n "${cask}" ]] || continue
    if ! "${nb_cmd}" install --cask "${cask}"; then
      if [[ "${cask}" == font-* ]]; then
        log "Skipping ${cask}: nanobrew could not install this font"
      else
        failures+=("${cask}")
      fi
    fi
  done < <(bundle_cask_names "${bundle}")

  if ((${#failures[@]} > 0)); then
    die "failed to install casks: ${failures[*]}"
  fi
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
