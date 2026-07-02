#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

keep_temp="false"
smoke_home=""

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-setup-staged-smoke.sh [options]

Run the safe staged setup subset against a temporary HOME. This applies the
mise dotfiles slice and runs the post-apply Git/Git-signing/GitHub steps without
touching the real HOME.

Options:
  --keep-temp   Keep the temporary HOME for inspection.
  -h, --help    Show this help.
USAGE
}

cleanup() {
  if [[ "${keep_temp}" == "true" ]]; then
    printf 'smoke HOME: %s\n' "${smoke_home}" >&2
    return
  fi

  [[ -z "${smoke_home}" ]] || rm -rf "${smoke_home}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --keep-temp)
        keep_temp="true"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        error "unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

assert_exists() {
  local path="$1"

  if [[ ! -e "${path}" && ! -L "${path}" ]]; then
    error "expected staged setup output is missing: ${path}"
    return 1
  fi
}

assert_empty_file() {
  local path="$1"

  if [[ ! -f "${path}" ]]; then
    error "expected staged setup file is missing: ${path}"
    return 1
  fi

  if [[ -s "${path}" ]]; then
    error "expected staged setup file to be empty: ${path}"
    return 1
  fi
}

assert_absent() {
  local path="$1"

  if [[ -e "${path}" || -L "${path}" ]]; then
    error "unexpected staged setup output exists: ${path}"
    return 1
  fi
}

run_safe_staged_subset() {
  HOME="${smoke_home}" \
    "${SCRIPT_DIR}/mise-setup-staged.sh" \
      --force-dotfiles \
      --only mise:dotfiles:apply \
      --only install:common:git \
      --only install:common:git-signing \
      --only install:common:gh \
      >/dev/null
}

verify_smoke_home() {
  assert_exists "${smoke_home}/.zprofile"
  assert_exists "${smoke_home}/.config/mise/config.toml"
  assert_exists "${smoke_home}/.config/git/config"
  assert_exists "${smoke_home}/.config/git/config-composio"
  assert_exists "${smoke_home}/.config/git/ignore"
  assert_empty_file "${smoke_home}/.config/git/config-composio-signing"
  assert_empty_file "${smoke_home}/.config/git/allowed_signers"
  assert_absent "${smoke_home}/.gitconfig"
}

main() {
  parse_args "$@"
  trap cleanup EXIT

  if ! mise_bin >/dev/null 2>&1; then
    error "mise is missing"
    return 127
  fi

  smoke_home="$(mktemp -d)"
  log "Running staged setup smoke test against temporary HOME"
  run_safe_staged_subset
  verify_smoke_home
}

main "$@"
