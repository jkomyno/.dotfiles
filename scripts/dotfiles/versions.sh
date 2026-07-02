#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

MODE="check"
MINIMUM_RELEASE_AGE="${DOTFILES_MISE_MINIMUM_RELEASE_AGE}"
BUMP=false
TOOL_ARGS=()

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/versions.sh [--check|--write] [--bump] [--minimum-release-age AGE] [TOOL...]

Maintain third-party tool versions declared in home/dot_mise/config.toml.

Modes:
  --check   Show outdated tools and verify the lockfile can be refreshed.
  --write   Upgrade matching tools and refresh home/dot_mise/mise.lock.

By default, --write preserves configured ranges such as node = "24".
Use --bump only when you intentionally want mise to change requested versions.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      MODE="check"
      shift
      ;;
    --write)
      MODE="write"
      shift
      ;;
    --bump)
      BUMP=true
      shift
      ;;
    --minimum-release-age)
      [[ $# -ge 2 ]] || {
        error "--minimum-release-age requires a value"
        exit 2
      }
      MINIMUM_RELEASE_AGE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      TOOL_ARGS+=("$1")
      shift
      ;;
  esac
done

ensure_mise() {
  if ! mise_bin >/dev/null 2>&1; then
    error "mise is not available; run setup.sh first or install mise"
    exit 1
  fi
}

check_versions() {
  log "Checking mise tools from home/dot_mise/config.toml"
  run_source_mise outdated "${TOOL_ARGS[@]}" || {
    warn "mise outdated reported issues; this can happen before Node/npm-backed tools are installed"
  }

  log "Checking lock refresh for ${DOTFILES_MISE_PLATFORMS}"
  run_source_mise lock \
    --dry-run \
    --platform "${DOTFILES_MISE_PLATFORMS}" \
    --minimum-release-age "${MINIMUM_RELEASE_AGE}" \
    "${TOOL_ARGS[@]}"
}

write_versions() {
  local upgrade_args=(--yes --minimum-release-age "${MINIMUM_RELEASE_AGE}")
  if [[ "${BUMP}" == true ]]; then
    upgrade_args+=(--bump)
  fi

  log "Upgrading mise tools from source config"
  run_source_mise upgrade "${upgrade_args[@]}" "${TOOL_ARGS[@]}"

  log "Refreshing source mise.lock for ${DOTFILES_MISE_PLATFORMS}"
  run_source_mise lock \
    --platform "${DOTFILES_MISE_PLATFORMS}" \
    --minimum-release-age "${MINIMUM_RELEASE_AGE}" \
    "${TOOL_ARGS[@]}"
}

main() {
  ensure_mise
  case "${MODE}" in
    check)
      check_versions
      ;;
    write)
      write_versions
      ;;
    *)
      error "unknown mode: ${MODE}"
      return 2
      ;;
  esac
}

main "$@"
