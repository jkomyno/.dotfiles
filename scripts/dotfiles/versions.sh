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
Usage: scripts/dotfiles/versions.sh [--check|--write|--sync|--sync-check] [--bump] [--minimum-release-age AGE] [TOOL...]

Maintain third-party tool versions declared in target/home/.config/mise/config.toml.

Modes:
  --check   Show outdated tools and verify the lockfile can be refreshed.
  --write   Refresh the full catalog locks for all supported platforms.
  --sync    Install the active catalog using the pulled locks.
  --sync-check  Preview the locked install.

By default, --write preserves configured ranges such as node = "24".
Use --bump only when you intentionally want mise to change requested versions.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sync|--sync-check)
      MODE="${1#--}"
      shift
      ;;
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

# Bundle TOMLs keep one declaration per line. Compare the whole key so a tool
# such as "go" does not also match "cargo".
declares_tool() {
  local tool="$1"
  shift
  awk -F '[[:space:]]*=[[:space:]]*' -v tool="${tool}" '
    $1 == tool || $1 == "\"" tool "\"" { found = 1 }
    END { exit !found }
  ' "$@"
}

# mise attributes included requests to their parent when editing. For an
# explicit range change, open each declaring fragment as the project config.
bump_ranges() {
  local fragment tool args=() mise_cmd
  mise_cmd="$(mise_bin)"
  for fragment in "${DOTFILES_MISE_DIR}"/bundles/*.toml "${DOTFILES_MISE_DIR}/config.linux.toml"; do
    case "${fragment}" in
      *.linux.toml) is_linux || continue ;;
      */empty.toml) continue ;;
    esac
    args=()
    for tool in ${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"}; do
      if declares_tool "${tool}" "${fragment}"; then args+=("${tool}"); fi
    done
    if [[ ${#TOOL_ARGS[@]} -gt 0 && ${#args[@]} == 0 ]]; then continue; fi
    MISE_CEILING_PATHS="${DOTFILES_ROOT}" MISE_AUTO_ENV=false \
      MISE_GLOBAL_CONFIG_FILE="${DOTFILES_MISE_CONFIG}" \
      MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_MISE_DIR}" \
      MISE_DEFAULT_CONFIG_FILENAME="${fragment##*/}" \
      "${mise_cmd}" -C "${fragment%/*}" upgrade --no-global --bump --no-prune --yes \
        --minimum-release-age "${MINIMUM_RELEASE_AGE}" ${args[@]+"${args[@]}"}
  done
}

# With an explicit MISE_GLOBAL_CONFIG_FILE, mise treats config.linux.toml as
# a project overlay and writes mise.linux.lock with a project-scoped lock.
refresh_locks() {
  local common=(--minimum-release-age "${MINIMUM_RELEASE_AGE}")
  local tool shared=() linux=()
  if [[ "${MODE}" == check ]]; then common+=(--dry-run); else common+=(--bump); fi
  for tool in ${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"}; do
    if declares_tool "${tool}" "${DOTFILES_MISE_DIR}/config.linux.toml" "${DOTFILES_MISE_DIR}"/bundles/*.linux.toml; then
      linux+=("$tool")
    else
      shared+=("$tool")
    fi
  done
  if [[ ${#TOOL_ARGS[@]} == 0 || ${#shared[@]} -gt 0 ]]; then
    log "Refreshing shared lock for ${DOTFILES_MISE_PLATFORMS} (${MODE})"
    MISE_ENV='' DOTFILES_LOCK_CATALOG=1 run_source_mise_base lock --global "${common[@]}" \
      --platform "${DOTFILES_MISE_PLATFORMS}" ${shared[@]+"${shared[@]}"}
  fi
  if [[ ${#TOOL_ARGS[@]} == 0 || ${#linux[@]} -gt 0 ]]; then
    log "Refreshing Linux lock for ${DOTFILES_MISE_LINUX_PLATFORMS} (${MODE})"
    MISE_ENV=linux run_source_mise_base lock "${common[@]}" \
      --platform "${DOTFILES_MISE_LINUX_PLATFORMS}" ${linux[@]+"${linux[@]}"}
  fi
}

main() {
  ensure_mise
  profile_resolve
  case "${MODE}" in
    sync | sync-check)
      profile_report
      local install=(install --locked --yes)
      if [[ "${MODE}" == sync-check ]]; then install+=(--dry-run); fi
      run_source_mise "${install[@]}" ${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"}
      ;;
    check | write)
      # Maintaining the repository locks always resolves the complete catalog,
      # independently of which tools this host has adopted.
      profile_resolve full
      profile_report
      if [[ "${MODE}" == check ]]; then
        run_source_mise outdated ${TOOL_ARGS[@]+"${TOOL_ARGS[@]}"} || warn "mise outdated could not resolve all tools"
      fi
      if [[ "${BUMP}" == true && "${MODE}" == write ]]; then
        bump_ranges
      fi
      refresh_locks
      ;;
  esac
}

main "$@"
