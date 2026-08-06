#!/usr/bin/env bash
# agents.sh — make coding-agent marketplaces and plugins reproducible.
#
# Claude Code settings.json enables plugins by `<plugin>@<marketplace>` id, but
# enabling a plugin does not install it. Codex stores plugin state under its own
# runtime directory. This script registers each declared marketplace and installs
# each declared plugin, so a fresh machine ends up with the plugins this repo
# expects.
#
# It is idempotent and safe to re-run. When Claude Code is not installed yet
# (e.g. mid-bootstrap on a blank Mac), or Codex is not installed yet, that host
# skips with a hint instead of failing.
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
CLAUDE_SKILL_LINKS="${ROOT}/scripts/dotfiles/claude-skill-links.sh"

CLAUDE=""
CODEX=""
FAILURES=0

remove_legacy_lattice_hooks_from() {
  local file="$1" tmp file_mode
  [[ -f "${file}" ]] || return 0

  tmp="$(mktemp)"
  if ! jq '
    if (.hooks? | type) != "object" then .
    else
      .hooks |= with_entries(
        .value |= map(
          .hooks |= map(select((.command // "") | test("lattice"; "i") | not))
          | select((.hooks | length) > 0)
        )
        | select((.value | length) > 0)
      )
    end
  ' "${file}" >"${tmp}"; then
    rm -f "${tmp}"
    warn "could not parse agent hook config: ${file}"
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  if cmp -s "${file}" "${tmp}"; then
    rm -f "${tmp}"
    return 0
  fi

  if [[ "${MODE}" == "check" ]]; then
    rm -f "${tmp}"
    info "legacy Lattice hooks present in ${file} (would remove)"
    return 0
  fi

  file_mode="$(stat -f '%Lp' "${file}" 2>/dev/null || stat -c '%a' "${file}")"
  chmod "${file_mode}" "${tmp}"
  mv "${tmp}" "${file}"
  info "removed legacy Lattice hooks from ${file}"
}

remove_legacy_lattice_hooks() {
  remove_legacy_lattice_hooks_from "${HOME}/.claude/settings.json"
  remove_legacy_lattice_hooks_from "${CODEX_HOME:-${HOME}/.codex}/hooks.json"
}

sync_claude_skill_links() {
  local -a args=()
  [[ "${MODE}" == "check" ]] && args+=(--check)

  if ! bash "${CLAUDE_SKILL_LINKS}" ${args[@]+"${args[@]}"}; then
    warn "Claude managed-skill links did not converge"
    FAILURES=$((FAILURES + 1))
  fi
}

report_failures() {
  if [[ "${FAILURES}" -gt 0 ]]; then
    warn "${FAILURES} agent operation(s) failed; declared agent state not fully reproduced"
    return 1
  fi
}

claude_known_marketplaces() {
  "${CLAUDE}" plugin marketplace list --json 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

claude_installed_plugin_ids() {
  "${CLAUDE}" plugin list --json 2>/dev/null | jq -r '.[].id' 2>/dev/null || true
}

claude_marketplace_entries() {
  jq -r '.marketplaces[] | [.name, .source] | @tsv' "${DATA_FILE}"
}

claude_plugin_ids() {
  jq -r '.plugins[]' "${DATA_FILE}"
}

claude_mcp_entries() {
  jq -r '.mcpServers[]? | [.name, (.transport // "http"), .url] | @tsv' "${DATA_FILE}"
}

# `claude mcp get <name>` exits 0 when a server of that name is already
# configured in any scope, so it doubles as the idempotency probe. MCP servers
# are static (a name + transport + URL), so there is nothing to "update" once
# present; update mode only ensures a missing declaration gets added.
sync_claude_mcp_servers() {
  local name transport url
  while IFS=$'\t' read -r name transport url; do
    [[ -n "${name}" ]] || continue
    if "${CLAUDE}" mcp get "${name}" >/dev/null 2>&1; then
      case "${MODE}" in
        check) info "mcp: ${name} configured" ;;
        *) info "mcp: ${name} already configured" ;;
      esac
    else
      case "${MODE}" in
        check) info "mcp: ${name} MISSING (would add ${url})" ;;
        *)
          log "mcp: adding ${name} (${transport}) ${url}"
          "${CLAUDE}" mcp add --transport "${transport}" --scope user "${name}" "${url}" \
            || { warn "mcp add failed: ${name}"; FAILURES=$((FAILURES + 1)); }
          ;;
      esac
    fi
  done < <(claude_mcp_entries)
}

codex_bin() {
  if command -v codex >/dev/null 2>&1; then
    command -v codex
  elif [[ -x "${HOME}/.local/bin/codex" ]]; then
    printf '%s\n' "${HOME}/.local/bin/codex"
  else
    return 1
  fi
}

codex_known_marketplaces() {
  "${CODEX}" plugin marketplace list --json 2>/dev/null | jq -r '.marketplaces[].name' 2>/dev/null || true
}

codex_installed_plugin_ids() {
  "${CODEX}" plugin list --json 2>/dev/null | jq -r '.installed[].pluginId' 2>/dev/null || true
}

codex_marketplace_entries() {
  jq -r '.codex.marketplaces[]? | [.name, .source] | @tsv' "${DATA_FILE}"
}

# `~/.codex/config.toml` is deployed by mise bootstrap dotfiles in `mode = "copy"`, and
# Codex appends its machine-local [marketplaces.*]/[plugins.*] state there at
# runtime. A re-apply (e.g. a forced first-run `mise bootstrap dotfiles apply`) re-copies
# the curated seed and wipes that appended state, but leaves the marketplace
# clone under ~/.codex/.tmp/marketplaces/<name> in place. In that desynced state
# `codex plugin marketplace add` refuses with "already added from a different
# source" and never repairs config.toml, so the marketplace stays out of scope
# and plugin installs fail with "not found in marketplace". Clearing the stale
# clone lets the add re-register the marketplace and rewrite config.toml.
codex_marketplace_add() {
  local name="$1" source="$2"
  # This runs only when the marketplace is not currently in scope (the add
  # branch), so any clone left under ~/.codex/.tmp/marketplaces/<name> is
  # orphaned: config.toml was redeployed by mise in copy mode and lost the
  # [marketplaces.<name>] entry codex appends at runtime. Left in place, codex
  # refuses the re-add with "already added from a different source" instead of
  # repairing config. Clear it up front so the add cleanly re-registers the
  # marketplace and rewrites config.toml.
  local stale="${CODEX_HOME:-${HOME}/.codex}/.tmp/marketplaces/${name}"
  if [[ -d "${stale}" ]]; then
    warn "codex marketplace: clearing orphaned clone ${stale} before re-adding"
    rm -rf -- "${stale}"
  fi
  "${CODEX}" plugin marketplace add "${source}"
}

codex_plugin_ids() {
  jq -r '.codex.plugins[]?' "${DATA_FILE}"
}

sync_claude_marketplaces() {
  local known name source
  known="$(claude_known_marketplaces)"

  while IFS=$'\t' read -r name source; do
    [[ -n "${name}" ]] || continue
    if grep -qxF "${name}" <<<"${known}"; then
      case "${MODE}" in
        update)
          log "marketplace: updating ${name}"
          "${CLAUDE}" plugin marketplace update "${name}" \
            || { warn "marketplace update failed: ${name}"; FAILURES=$((FAILURES + 1)); }
          ;;
        check) info "marketplace: ${name} present" ;;
        install) info "marketplace: ${name} already registered" ;;
      esac
    else
      case "${MODE}" in
        check) info "marketplace: ${name} MISSING (would add ${source})" ;;
        *)
          log "marketplace: adding ${name} from ${source}"
          "${CLAUDE}" plugin marketplace add "${source}" \
            || { warn "marketplace add failed: ${source}"; FAILURES=$((FAILURES + 1)); }
          ;;
      esac
    fi
  done < <(claude_marketplace_entries)
}

sync_claude_plugins() {
  local installed id
  installed="$(claude_installed_plugin_ids)"

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if grep -qxF "${id}" <<<"${installed}"; then
      case "${MODE}" in
        update)
          log "plugin: updating ${id}"
          "${CLAUDE}" plugin update "${id}" \
            || { warn "plugin update failed: ${id}"; FAILURES=$((FAILURES + 1)); }
          ;;
        check) info "plugin: ${id} installed" ;;
        install) info "plugin: ${id} already installed" ;;
      esac
    else
      case "${MODE}" in
        check) info "plugin: ${id} MISSING (would install)" ;;
        *)
          log "plugin: installing ${id}"
          "${CLAUDE}" plugin install "${id}" \
            || { warn "plugin install failed: ${id}"; FAILURES=$((FAILURES + 1)); }
          ;;
      esac
    fi
  done < <(claude_plugin_ids)
}

sync_codex_marketplaces() {
  local known name source
  known="$(codex_known_marketplaces)"

  while IFS=$'\t' read -r name source; do
    [[ -n "${name}" ]] || continue
    if grep -qxF "${name}" <<<"${known}"; then
      case "${MODE}" in
        update)
          log "codex marketplace: updating ${name}"
          "${CODEX}" plugin marketplace upgrade "${name}" \
            || { warn "codex marketplace update failed: ${name}"; FAILURES=$((FAILURES + 1)); }
          ;;
        check) info "codex marketplace: ${name} present" ;;
        install) info "codex marketplace: ${name} already registered" ;;
      esac
    else
      case "${MODE}" in
        check) info "codex marketplace: ${name} MISSING (would add ${source})" ;;
        *)
          log "codex marketplace: adding ${name} from ${source}"
          codex_marketplace_add "${name}" "${source}" \
            || { warn "codex marketplace add failed: ${source}"; FAILURES=$((FAILURES + 1)); }
          ;;
      esac
    fi
  done < <(codex_marketplace_entries)
}

sync_codex_plugins() {
  local installed id
  installed="$(codex_installed_plugin_ids)"

  while IFS= read -r id; do
    [[ -n "${id}" ]] || continue
    if grep -qxF "${id}" <<<"${installed}"; then
      case "${MODE}" in
        update) info "codex plugin: ${id} already installed (marketplace refreshed)" ;;
        check) info "codex plugin: ${id} installed" ;;
        install) info "codex plugin: ${id} already installed" ;;
      esac
    else
      case "${MODE}" in
        check) info "codex plugin: ${id} MISSING (would install)" ;;
        *)
          log "codex plugin: installing ${id}"
          "${CODEX}" plugin add "${id}" \
            || { warn "codex plugin install failed: ${id}"; FAILURES=$((FAILURES + 1)); }
          ;;
      esac
    fi
  done < <(codex_plugin_ids)
}

sync_claude() {
  if ! CLAUDE="$(claude_bin)"; then
    log "Skipping Claude plugin sync because the claude CLI is not installed yet"
    log "Re-run after installing Claude Code: just update plugins"
    return 0
  fi

  log "Claude plugin sync (${MODE}) using ${DATA_FILE#"${ROOT}"/}"
  sync_claude_marketplaces
  sync_claude_plugins
  sync_claude_mcp_servers

  if [[ "${MODE}" != "check" ]]; then
    info "Restart Claude Code for plugin changes to take effect"
  fi
}

sync_codex() {
  if ! CODEX="$(codex_bin)"; then
    log "Skipping Codex plugin sync because the codex CLI is not installed yet"
    log "Re-run after installing Codex: just update plugins"
    return 0
  fi

  if [[ -z "$(codex_marketplace_entries)" && -z "$(codex_plugin_ids)" ]]; then
    info "Codex plugin sync: no configured Codex plugins"
    return 0
  fi

  log "Codex plugin sync (${MODE}) using ${DATA_FILE#"${ROOT}"/}"
  sync_codex_marketplaces
  sync_codex_plugins

  if [[ "${MODE}" != "check" ]]; then
    info "Restart Codex for plugin changes to take effect"
  fi
}

main() {
  [[ -f "${DATA_FILE}" ]] || die "missing plugin manifest: ${DATA_FILE}"
  [[ -f "${CLAUDE_SKILL_LINKS}" ]] || die "missing Claude skill-link helper: ${CLAUDE_SKILL_LINKS}"

  sync_claude_skill_links
  activate_mise
  export PATH="${HOME}/.local/bin:${PATH}"

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not available yet; skipping agent plugin sync"
    report_failures
    return
  fi

  remove_legacy_lattice_hooks
  sync_claude
  sync_codex

  # Absent jq/agent CLIs already returned 0 above (a fresh machine is expected
  # to skip). A real command failure once a host CLI is present is a genuine
  # error: tracked config still declares these plugins, so report non-zero so
  # callers can see the declared plugin state was not fully reproduced.
  report_failures
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
