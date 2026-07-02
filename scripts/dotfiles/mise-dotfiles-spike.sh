#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

keep_temp="false"
install_spike="false"
spike_root=""
spike_home=""

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-dotfiles-spike.sh [options]

Run a disposable mise dotfiles spike against a temporary HOME.

Options:
  --install     Run `mise system install --yes` against the temporary HOME
                after the dry-run succeeds.
  --keep-temp   Keep the temporary project and HOME directories for inspection.
  -h, --help    Show this help.

This script never writes to the real HOME.
USAGE
}

cleanup() {
  if [[ "${keep_temp}" == "true" ]]; then
    printf 'spike project: %s\n' "${spike_root}" >&2
    printf 'spike HOME:    %s\n' "${spike_home}" >&2
    return
  fi

  [[ -z "${spike_root}" ]] || rm -rf "${spike_root}"
  [[ -z "${spike_home}" ]] || rm -rf "${spike_home}"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --install)
        install_spike="true"
        ;;
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

require_mise_dotfiles() {
  local mise_cmd="$1"
  local neutral_dir
  neutral_dir="$(mktemp -d)"

  if MISE_EXPERIMENTAL=true "${mise_cmd}" -C "${neutral_dir}" dotfiles status --help >/dev/null 2>&1; then
    rm -rf "${neutral_dir}"
    return 0
  fi
  rm -rf "${neutral_dir}"

  error "mise dotfiles support is unavailable in: $("${mise_cmd}" --version 2>/dev/null || printf 'unknown')"
  error "retry this spike with a mise release that exposes the experimental 'dotfiles' command"
  return 1
}

write_spike_project() {
  spike_root="$(mktemp -d)"
  spike_home="$(mktemp -d)"

  mkdir -p "${spike_root}/target/home/.config/dotfiles-spike"
  cat >"${spike_root}/target/home/.config/dotfiles-spike/config.toml" <<'TOML'
[spike]
manager = "mise-dotfiles"
TOML

  cat >"${spike_root}/mise.toml" <<'TOML'
[dotfiles]
"~/.config/dotfiles-spike/config.toml" = { source = "target/home/.config/dotfiles-spike/config.toml", mode = "symlink" }
TOML
}

run_mise_dotfiles() {
  local mise_cmd="$1"
  shift

  env \
    HOME="${spike_home}" \
    MISE_EXPERIMENTAL=true \
    MISE_TRUSTED_CONFIG_PATHS="${spike_root}/mise.toml${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${spike_root}" dotfiles "$@"
}

verify_installed_spike() {
  local target="${spike_home}/.config/dotfiles-spike/config.toml"
  local expected="${spike_root}/target/home/.config/dotfiles-spike/config.toml"
  local actual_link
  local actual_resolved
  local expected_resolved

  if [[ ! -L "${target}" ]]; then
    error "expected symlink was not created: ${target}"
    return 1
  fi

  actual_link="$(readlink "${target}")"
  actual_resolved="$(cd -- "$(dirname -- "${actual_link}")" && pwd -P)/$(basename -- "${actual_link}")"
  expected_resolved="$(cd -- "$(dirname -- "${expected}")" && pwd -P)/$(basename -- "${expected}")"

  if [[ "${actual_resolved}" != "${expected_resolved}" ]]; then
    error "symlink points at unexpected source: ${actual_link}"
    return 1
  fi

  pass "temporary dotfiles symlink was created"
}

pass() {
  printf 'ok: %s\n' "$*"
}

main() {
  parse_args "$@"
  trap cleanup EXIT

  local mise_cmd
  mise_cmd="$(mise_bin)" || {
    error "mise is missing"
    return 127
  }

  log "Checking mise dotfiles support"
  require_mise_dotfiles "${mise_cmd}"

  write_spike_project
  log "Running disposable dotfiles status"
  run_mise_dotfiles "${mise_cmd}" status

  log "Running disposable dotfiles dry-run"
  run_mise_dotfiles "${mise_cmd}" apply --dry-run

  if [[ "${install_spike}" == "true" ]]; then
    log "Installing into temporary HOME"
    run_mise_dotfiles "${mise_cmd}" apply --yes
    verify_installed_spike
  fi
}

main "$@"
