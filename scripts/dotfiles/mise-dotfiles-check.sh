#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

keep_temp="false"
check_home=""

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-dotfiles-check.sh [options]

Validate the repository's experimental mise [dotfiles] entries against a
temporary HOME. This does not write to the real HOME.

Options:
  --keep-temp   Keep the temporary HOME for inspection.
  -h, --help    Show this help.
USAGE
}

cleanup() {
  if [[ "${keep_temp}" == "true" ]]; then
    printf 'check HOME: %s\n' "${check_home}" >&2
    return
  fi

  [[ -z "${check_home}" ]] || rm -rf "${check_home}"
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

run_mise_dotfiles() {
  local mise_cmd="$1"
  shift

  env \
    HOME="${check_home}" \
    MISE_EXPERIMENTAL=true \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}/mise.toml${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${DOTFILES_ROOT}" dotfiles "$@"
}

verify_symlink() {
  local target_rel="$1"
  local source="$2"
  local target_path="${check_home}/${target_rel}"
  local source_path="${DOTFILES_ROOT}/${source}"
  local actual_link
  local actual_resolved
  local expected_resolved

  if [[ ! -L "${target_path}" ]]; then
    error "expected symlink was not created: ${target_path}"
    return 1
  fi

  actual_link="$(readlink "${target_path}")"
  actual_resolved="$(cd -- "$(dirname -- "${actual_link}")" && pwd -P)/$(basename -- "${actual_link}")"
  expected_resolved="$(cd -- "$(dirname -- "${source_path}")" && pwd -P)/$(basename -- "${source_path}")"

  if [[ "${actual_resolved}" != "${expected_resolved}" ]]; then
    error "symlink ${target_path} points at unexpected source: ${actual_link}"
    return 1
  fi
}

verify_dotfiles() {
  verify_symlink ".config/starship.toml" "target/home/.config/starship.toml"
  verify_symlink ".config/ripgrep/config" "target/home/.config/ripgrep/config"
}

main() {
  parse_args "$@"
  trap cleanup EXIT

  local mise_cmd
  mise_cmd="$(mise_bin)" || {
    error "mise is missing"
    return 127
  }

  check_home="$(mktemp -d)"

  log "Checking repository mise dotfiles status against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" status

  log "Checking repository mise dotfiles dry-run against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --dry-run

  log "Applying repository mise dotfiles into temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --yes
  verify_dotfiles
}

main "$@"
