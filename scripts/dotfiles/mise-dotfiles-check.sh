#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

keep_temp="false"
check_home=""
legacy_home=""
unrelated_home=""

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

  local temp_home
  for temp_home in "${check_home}" "${legacy_home}" "${unrelated_home}"; do
    [[ -z "${temp_home}" ]] || rm -rf "${temp_home}"
  done
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
  if [[ "${actual_link}" == /* ]]; then
    actual_resolved="$(cd -- "$(dirname -- "${actual_link}")" && pwd -P)/$(basename -- "${actual_link}")"
  else
    actual_resolved="$(cd -- "$(dirname -- "${target_path}")/$(dirname -- "${actual_link}")" && pwd -P)/$(basename -- "${actual_link}")"
  fi
  expected_resolved="$(cd -- "$(dirname -- "${source_path}")" && pwd -P)/$(basename -- "${source_path}")"

  if [[ "${actual_resolved}" != "${expected_resolved}" ]]; then
    error "symlink ${target_path} points at unexpected source: ${actual_link}"
    return 1
  fi
}

verify_file_exists() {
  local target_rel="$1"

  if [[ ! -f "${check_home}/${target_rel}" ]]; then
    error "expected file was not created: ${target_rel}"
    return 1
  fi
}

verify_file_matches_source() {
  local target_rel="$1"
  local source="$2"

  verify_file_exists "${target_rel}" || return 1

  if ! cmp -s "${DOTFILES_ROOT}/${source}" "${check_home}/${target_rel}"; then
    error "copied file ${target_rel} differs from ${source}"
    diff -u "${DOTFILES_ROOT}/${source}" "${check_home}/${target_rel}" >&2 || true
    return 1
  fi
}

verify_no_template_delimiters() {
  local target_rel="$1"

  verify_file_exists "${target_rel}" || return 1

  if grep -Eq '\{\{|%\}' "${check_home}/${target_rel}"; then
    error "rendered file still contains template delimiters: ${target_rel}"
    return 1
  fi
}

verify_json() {
  local target_rel="$1"

  if ! have python3; then
    return
  fi

  if ! python3 -m json.tool "${check_home}/${target_rel}" >/dev/null; then
    error "rendered JSON is invalid: ${target_rel}"
    return 1
  fi
}

verify_agent_skill_links() {
  verify_symlink ".agents/skills" "target/home/.agents/skills"

  if [[ -L "${check_home}/.claude/skills" || ! -d "${check_home}/.claude/skills" ]]; then
    error "Claude skills must remain a real directory for host-specific entries"
    return 1
  fi

  if [[ ! -f "${check_home}/.agents/skills/sync-skills/SKILL.md" ]]; then
    error "canonical agent skills symlink does not expose sync-skills"
    return 1
  fi

  if [[ "$(<"${check_home}/.claude/skills/looper/SKILL.md")" != "local-only" ]]; then
    error "Claude skill linking replaced the local-only looper skill"
    return 1
  fi

  if [[ "$(readlink "${check_home}/.claude/skills/plugin-owned")" != "${check_home}/plugin-skills" ]]; then
    error "Claude skill linking replaced the host-owned plugin symlink"
    return 1
  fi

  if [[ "$(readlink "${check_home}/.claude/skills/alias-sync")" != "../../.agents/skills/sync-skills" ]]; then
    error "Claude skill linking removed a host-owned alias into managed skills"
    return 1
  fi

  if [[ -e "${check_home}/.claude/skills/retired" || -L "${check_home}/.claude/skills/retired" ]]; then
    error "Claude skill linking preserved a stale managed link"
    return 1
  fi

  verify_symlink ".claude/skills/sync-skills" "target/home/.agents/skills/sync-skills"

  if [[ ! -f "${check_home}/.claude/skills/sync-skills/SKILL.md" ]]; then
    error "Claude skill links do not expose sync-skills"
    return 1
  fi
}

seed_local_claude_skill() {
  mkdir -p "${check_home}/.claude/skills/looper" "${check_home}/plugin-skills"
  printf 'local-only\n' >"${check_home}/.claude/skills/looper/SKILL.md"
  printf 'plugin-owned\n' >"${check_home}/plugin-skills/SKILL.md"
  ln -s "${check_home}/plugin-skills" "${check_home}/.claude/skills/plugin-owned"
  ln -s "../../.agents/skills/sync-skills" "${check_home}/.claude/skills/alias-sync"
  ln -s "../../.agents/skills/retired" "${check_home}/.claude/skills/retired"
}

run_claude_skill_links() {
  local target_home="$1"
  shift
  env \
    HOME="${target_home}" \
    DOTFILES="${DOTFILES_ROOT}" \
    bash "${SCRIPT_DIR}/claude-skill-links.sh" "$@"
}

verify_check_mode() {
  if run_claude_skill_links "${check_home}" --check; then
    error "Claude skill-link check unexpectedly passed with pending changes"
    return 1
  fi

  [[ "$(<"${check_home}/.claude/skills/looper/SKILL.md")" == "local-only" ]] || return 1
  [[ "$(readlink "${check_home}/.claude/skills/plugin-owned")" == "${check_home}/plugin-skills" ]] || return 1
  [[ -L "${check_home}/.claude/skills/retired" ]] || return 1
}

verify_legacy_directory_link_migration() {
  legacy_home="$(mktemp -d)"
  mkdir -p "${legacy_home}/.agents" "${legacy_home}/.claude"
  ln -s "${DOTFILES_ROOT}/target/home/.agents/skills" "${legacy_home}/.agents/skills"
  ln -s "../.agents/skills" "${legacy_home}/.claude/skills"

  run_claude_skill_links "${legacy_home}"
  if [[ -L "${legacy_home}/.claude/skills" || ! -d "${legacy_home}/.claude/skills" ]]; then
    error "legacy Claude skills link was not migrated to a real directory"
    return 1
  fi
  [[ -L "${legacy_home}/.claude/skills/sync-skills" ]] || return 1
  run_claude_skill_links "${legacy_home}" --check
}

verify_unrelated_directory_link_is_preserved() {
  unrelated_home="$(mktemp -d)"
  mkdir -p "${unrelated_home}/.agents" "${unrelated_home}/.claude" "${unrelated_home}/host-skills"
  printf 'host-owned\n' >"${unrelated_home}/host-skills/SKILL.md"
  ln -s "../host-skills" "${unrelated_home}/.claude/skills"

  if run_claude_skill_links "${unrelated_home}"; then
    error "unrelated Claude skills directory link was replaced"
    return 1
  fi
  [[ "$(readlink "${unrelated_home}/.claude/skills")" == "../host-skills" ]] || return 1
  [[ "$(<"${unrelated_home}/.claude/skills/SKILL.md")" == "host-owned" ]] || return 1
}

verify_dotfiles() {
  verify_no_template_delimiters ".zprofile"
  verify_no_template_delimiters ".claude/settings.json"
  verify_no_template_delimiters "Library/LaunchAgents/sh.paseo.daemon.plist"
  verify_json ".claude/settings.json"
  verify_file_matches_source ".pi/agent/settings.json" "target/home/.pi/agent/settings.json"
  verify_symlink ".pi/agent/extensions/agentmemory" "target/home/.pi/agent/extensions/agentmemory"
  verify_agent_skill_links
  verify_file_matches_source "Library/Application Support/com.pais.handy/settings_store.json" "target/home/.handy/settings_store.json"
  verify_file_matches_source ".config/gh/config.yml" "target/home/.config/gh/config.yml"
  verify_file_matches_source ".ssh/config" "target/home/.ssh/config"
  verify_file_matches_source ".config/ccstatusline/settings.json" "target/home/.config/ccstatusline/settings.json"
  verify_symlink ".config/ghostty/config" "target/home/.config/ghostty/config"
  verify_file_matches_source ".config/ghui/config.json" "target/home/.config/ghui/config.json"
  verify_symlink ".config/hunk/config.toml" "target/home/.config/hunk/config.toml"
  verify_symlink ".config/mise/config.toml" "target/home/.config/mise/config.toml"
  verify_symlink ".config/mise/mise.lock" "target/home/.config/mise/mise.lock"
  verify_symlink ".config/ripgrep/config" "target/home/.config/ripgrep/config"
  verify_symlink ".config/starship.toml" "target/home/.config/starship.toml"
  verify_symlink ".config/tmux/tmux.conf" "target/home/.config/tmux/tmux.conf"
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
  seed_local_claude_skill

  log "Checking repository mise dotfiles status against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" status

  log "Checking repository mise dotfiles dry-run against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --dry-run

  log "Applying repository mise dotfiles into temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --yes
  verify_check_mode
  run_claude_skill_links "${check_home}"
  run_claude_skill_links "${check_home}" --check
  verify_dotfiles
  verify_legacy_directory_link_migration
  verify_unrelated_directory_link_is_preserved
  bash "${SCRIPT_DIR}/update-flow-check.sh"
}

main "$@"
