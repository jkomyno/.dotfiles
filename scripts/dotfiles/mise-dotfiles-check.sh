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

verify_rendered_template() {
  local target_rel="$1"
  local source_template="$2"
  local rendered_path="${check_home}/${target_rel}"
  local expected_path

  expected_path="$(mktemp)"
  if ! HOME="${check_home}" run_chezmoi_source execute-template < "${DOTFILES_ROOT}/${source_template}" > "${expected_path}"; then
    rm -f "${expected_path}"
    return 1
  fi

  if ! cmp -s "${expected_path}" "${rendered_path}"; then
    error "rendered template ${target_rel} differs from ${source_template}"
    diff -u "${expected_path}" "${rendered_path}" >&2 || true
    rm -f "${expected_path}"
    return 1
  fi

  rm -f "${expected_path}"
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
  verify_symlink ".claude/skills" "target/home/.agents/skills"

  if [[ ! -f "${check_home}/.agents/skills/sync-skills/SKILL.md" ]]; then
    error "canonical agent skills symlink does not expose sync-skills"
    return 1
  fi

  if [[ ! -f "${check_home}/.claude/skills/sync-skills/SKILL.md" ]]; then
    error "Claude skills symlink does not expose sync-skills"
    return 1
  fi
}

verify_dotfiles() {
  verify_rendered_template ".zprofile" "home/dot_zprofile.tmpl"
  verify_rendered_template ".claude/settings.json" "home/dot_claude/settings.json.tmpl"
  verify_json ".claude/settings.json"
  verify_agent_skill_links
  verify_symlink ".config/ccstatusline/settings.json" "target/home/.config/ccstatusline/settings.json"
  verify_symlink ".config/ghostty/config" "target/home/.config/ghostty/config"
  verify_symlink ".config/ghui/config.json" "target/home/.config/ghui/config.json"
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

  log "Checking repository mise dotfiles status against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" status

  log "Checking repository mise dotfiles dry-run against temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --dry-run

  log "Applying repository mise dotfiles into temporary HOME"
  run_mise_dotfiles "${mise_cmd}" apply --yes
  verify_dotfiles
}

main "$@"
