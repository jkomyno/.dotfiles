#!/usr/bin/env bash
# agents.sh — make Claude Code marketplaces and plugins reproducible.
#
# settings.json enables plugins by `<plugin>@<marketplace>` id, but enabling a
# plugin does not install it. This script registers each marketplace and installs
# each enabled plugin declared in scripts/dotfiles/agent-plugins.json, so a fresh
# machine ends up with exactly the plugins this repo expects.
#
# It is idempotent and safe to re-run. When Claude Code is not installed yet
# (e.g. mid-bootstrap on a blank Mac), it skips with a hint instead of failing.
#
# Modes:
#   (default)  Install: add missing marketplaces, install missing plugins.
#   --update   Refresh all marketplaces, then update every configured plugin.
#   --check    Read-only: report configured vs installed. No mutation.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

MODE="install"

log() { printf '==> %s\n' "$*" >&2; }
info() { printf 'info: %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update) MODE="update" ;;
    --check | --plan) MODE="check" ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

repo_root() {
  if [[ -n "${MISE_PROJECT_ROOT:-}" ]]; then
    printf '%s\n' "${MISE_PROJECT_ROOT}"
    return
  fi
  if [[ -n "${DOTFILES:-}" ]]; then
    printf '%s\n' "${DOTFILES}"
    return
  fi
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P
}

activate_mise() {
  if [[ -x "${HOME}/.local/bin/mise" ]]; then
    eval "$("${HOME}/.local/bin/mise" activate bash)" 2>/dev/null || true
  elif command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
}

claude_bin() {
  if command -v claude >/dev/null 2>&1; then
    command -v claude
  elif [[ -x "${HOME}/.local/bin/claude" ]]; then
    printf '%s\n' "${HOME}/.local/bin/claude"
  else
    return 1
  fi
}

ROOT="$(repo_root)"
DATA_FILE="${ROOT}/scripts/dotfiles/agent-plugins.json"

CLAUDE=""

known_marketplaces() {
  "${CLAUDE}" plugin marketplace list --json 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

installed_plugin_ids() {
  "${CLAUDE}" plugin list --json 2>/dev/null | jq -r '.[].id' 2>/dev/null || true
}

marketplace_entries() {
  jq -r '.marketplaces[] | [.name, .source] | @tsv' "${DATA_FILE}"
}

plugin_ids() {
  jq -r '.plugins[]' "${DATA_FILE}"
}

sync_marketplaces() {
  local known name source
  known="$(known_marketplaces)"

  while IFS=$'\t' read -r name source; do
    [[ -n "${name}" ]] || continue
    if grep -qxF "${name}" <<<"${known}"; then
      case "${MODE}" in
        update)
          log "marketplace: updating ${name}"
          "${CLAUDE}" plugin marketplace update "${name}" || warn "marketplace update failed: ${name}"
          ;;
        check) info "marketplace: ${name} present" ;;
        install) info "marketplace: ${name} already registered" ;;
      esac
    else
      case "${MODE}" in
        check) info "marketplace: ${name} MISSING (would add ${source})" ;;
        *)
          log "marketplace: adding ${name} from ${source}"
          "${CLAUDE}" plugin marketplace add "${source}" || warn "marketplace add failed: ${source}"
          ;;
      esac
    fi
  done < <(marketplace_entries)
}

sync_plugins() {
  local installed id
  installed="$(installed_plugin_ids)"

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if grep -qxF "${id}" <<<"${installed}"; then
      case "${MODE}" in
        update)
          log "plugin: updating ${id}"
          "${CLAUDE}" plugin update "${id}" || warn "plugin update failed: ${id}"
          ;;
        check) info "plugin: ${id} installed" ;;
        install) info "plugin: ${id} already installed" ;;
      esac
    else
      case "${MODE}" in
        check) info "plugin: ${id} MISSING (would install)" ;;
        *)
          log "plugin: installing ${id}"
          "${CLAUDE}" plugin install "${id}" || warn "plugin install failed: ${id}"
          ;;
      esac
    fi
  done < <(plugin_ids)
}

main() {
  [[ -f "${DATA_FILE}" ]] || die "missing plugin manifest: ${DATA_FILE}"

  activate_mise
  export PATH="${HOME}/.local/bin:${PATH}"

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not available yet; skipping Claude plugin sync"
    return 0
  fi

  if ! CLAUDE="$(claude_bin)"; then
    log "Skipping Claude plugin sync because the claude CLI is not installed yet"
    log "Re-run after installing Claude Code: just update plugins"
    return 0
  fi

  log "Claude plugin sync (${MODE}) using ${DATA_FILE#"${ROOT}"/}"
  sync_marketplaces
  sync_plugins

  if [[ "${MODE}" != "check" ]]; then
    info "Restart Claude Code for plugin changes to take effect"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
