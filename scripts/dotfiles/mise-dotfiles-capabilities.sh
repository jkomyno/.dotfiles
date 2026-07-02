#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

keep_temp="false"
cap_root=""
cap_home=""

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-dotfiles-capabilities.sh [options]

Probe mise dotfiles capabilities against a disposable project and HOME.
This never writes to the real HOME.

Options:
  --keep-temp   Keep the temporary project and HOME directories for inspection.
  -h, --help    Show this help.
USAGE
}

cleanup() {
  if [[ "${keep_temp}" == "true" ]]; then
    printf 'capability project: %s\n' "${cap_root}" >&2
    printf 'capability HOME:    %s\n' "${cap_home}" >&2
    return
  fi

  [[ -z "${cap_root}" ]] || rm -rf "${cap_root}"
  [[ -z "${cap_home}" ]] || rm -rf "${cap_home}"
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

pass() {
  printf 'ok: %s\n' "$*"
}

assert_file_content() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(cat "${path}")"

  if [[ "${actual}" != "${expected}" ]]; then
    error "unexpected content for ${path}: ${actual@Q}"
    return 1
  fi
}

assert_symlink_target() {
  local target="$1"
  local expected="$2"
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
    error "symlink ${target} points at unexpected source: ${actual_link}"
    return 1
  fi
}

run_mise_dotfiles() {
  local mise_cmd="$1"
  shift

  env \
    HOME="${cap_home}" \
    MISE_EXPERIMENTAL=true \
    MISE_TRUSTED_CONFIG_PATHS="${cap_root}/mise.toml${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    TEST_MISE_DOTFILES_TEMPLATE_VALUE="rendered-from-env" \
    "${mise_cmd}" -C "${cap_root}" dotfiles "$@"
}

write_capability_project() {
  cap_root="$(mktemp -d)"
  cap_home="$(mktemp -d)"

  mkdir -p "${cap_root}/target/home/.config/mise-capabilities/source-dir"
  printf 'symlink-source\n' >"${cap_root}/target/home/.config/mise-capabilities/symlink.txt"
  printf 'copy-source\n' >"${cap_root}/target/home/.config/mise-capabilities/copy.txt"
  printf 'template {{ env.TEST_MISE_DOTFILES_TEMPLATE_VALUE }}\n' >"${cap_root}/target/home/.config/mise-capabilities/template.txt"
  printf 'nested-source\n' >"${cap_root}/target/home/.config/mise-capabilities/source-dir/nested.txt"
  printf 'force-symlink-source\n' >"${cap_root}/target/home/.config/mise-capabilities/force-symlink.txt"
  printf 'force-copy-source\n' >"${cap_root}/target/home/.config/mise-capabilities/force-copy.txt"

  cat >"${cap_root}/mise.toml" <<'TOML'
[dotfiles]
"~/.config/mise-capabilities/symlink.txt" = { source = "target/home/.config/mise-capabilities/symlink.txt", mode = "symlink" }
"~/.config/mise-capabilities/copy.txt" = { source = "target/home/.config/mise-capabilities/copy.txt", mode = "copy" }
"~/.config/mise-capabilities/template.txt" = { source = "target/home/.config/mise-capabilities/template.txt", mode = "template" }
"~/.config/mise-capabilities/source-dir" = { source = "target/home/.config/mise-capabilities/source-dir", mode = "symlink" }
"~/.config/mise-capabilities/force-symlink.txt" = { source = "target/home/.config/mise-capabilities/force-symlink.txt", mode = "symlink" }
"~/.config/mise-capabilities/force-copy.txt" = { source = "target/home/.config/mise-capabilities/force-copy.txt", mode = "copy" }
TOML
}

probe_modes() {
  local mise_cmd="$1"
  local home_marker="~"
  local target_root="${home_marker}/.config/mise-capabilities"

  log "Probing symlink, copy, template, and directory symlink modes"
  run_mise_dotfiles "${mise_cmd}" status
  run_mise_dotfiles "${mise_cmd}" apply --dry-run
  run_mise_dotfiles "${mise_cmd}" apply --yes \
    "${target_root}/symlink.txt" \
    "${target_root}/copy.txt" \
    "${target_root}/template.txt" \
    "${target_root}/source-dir"

  assert_symlink_target \
    "${cap_home}/.config/mise-capabilities/symlink.txt" \
    "${cap_root}/target/home/.config/mise-capabilities/symlink.txt"
  pass "mode=symlink creates a symlink"

  if [[ -L "${cap_home}/.config/mise-capabilities/copy.txt" ]]; then
    error "mode=copy created a symlink"
    return 1
  fi
  assert_file_content "${cap_home}/.config/mise-capabilities/copy.txt" "copy-source"
  pass "mode=copy creates a regular file"

  assert_file_content "${cap_home}/.config/mise-capabilities/template.txt" "template rendered-from-env"
  pass "mode=template renders env-backed templates"

  assert_symlink_target \
    "${cap_home}/.config/mise-capabilities/source-dir" \
    "${cap_root}/target/home/.config/mise-capabilities/source-dir"
  assert_file_content "${cap_home}/.config/mise-capabilities/source-dir/nested.txt" "nested-source"
  pass "mode=symlink can target a whole directory"
}

probe_conflicts() {
  local mise_cmd="$1"
  local home_marker="~"
  local target_root="${home_marker}/.config/mise-capabilities"
  local conflict_output

  log "Probing conflict handling"
  printf 'existing-symlink-target\n' >"${cap_home}/.config/mise-capabilities/force-symlink.txt"
  printf 'existing-copy-target\n' >"${cap_home}/.config/mise-capabilities/force-copy.txt"

  set +e
  conflict_output="$(
    run_mise_dotfiles "${mise_cmd}" apply --yes \
      "${target_root}/force-symlink.txt" \
      "${target_root}/force-copy.txt" 2>&1
  )"
  local conflict_status=$?
  set -e

  if [[ ${conflict_status} -eq 0 ]]; then
    error "apply without --force unexpectedly overwrote existing files"
    return 1
  fi

  if [[ "${conflict_output}" != *"refusing to overwrite existing files"* ]]; then
    error "unexpected conflict output: ${conflict_output}"
    return 1
  fi
  assert_file_content "${cap_home}/.config/mise-capabilities/force-symlink.txt" "existing-symlink-target"
  assert_file_content "${cap_home}/.config/mise-capabilities/force-copy.txt" "existing-copy-target"
  pass "apply refuses existing whole-file targets without --force"

  run_mise_dotfiles "${mise_cmd}" apply --force --yes \
    "${target_root}/force-symlink.txt" \
    "${target_root}/force-copy.txt"
  assert_symlink_target \
    "${cap_home}/.config/mise-capabilities/force-symlink.txt" \
    "${cap_root}/target/home/.config/mise-capabilities/force-symlink.txt"
  assert_file_content "${cap_home}/.config/mise-capabilities/force-copy.txt" "force-copy-source"
  pass "apply --force replaces conflicting whole-file targets"
}

probe_literal_sources() {
  local mise_cmd="$1"
  local probe_root
  local probe_home
  local output
  local status

  probe_root="$(mktemp -d)"
  probe_home="$(mktemp -d)"
  mkdir -p "${probe_home}/.agents/skills/demo"
  printf 'demo\n' >"${probe_home}/.agents/skills/demo/SKILL.md"

  cat >"${probe_root}/mise.toml" <<'TOML'
[dotfiles]
"~/.claude/skills/demo" = { source = "{{ env.HOME }}/.agents/skills/demo", mode = "symlink" }
TOML

  log "Probing whether dotfile source paths are templated"
  set +e
  output="$(
    env \
      HOME="${probe_home}" \
      MISE_EXPERIMENTAL=true \
      MISE_TRUSTED_CONFIG_PATHS="${probe_root}/mise.toml" \
      "${mise_cmd}" -C "${probe_root}" dotfiles apply --yes 2>&1
  )"
  status=$?
  set -e

  rm -rf "${probe_root}" "${probe_home}"

  if [[ ${status} -eq 0 ]]; then
    error "dotfile source paths unexpectedly rendered templates"
    return 1
  fi

  if [[ "${output}" != *'{{ env.HOME }}'* ]]; then
    error "unexpected source-template probe output: ${output}"
    return 1
  fi

  pass "dotfile source paths are treated as literal paths"
}

main() {
  parse_args "$@"
  trap cleanup EXIT

  local mise_cmd
  mise_cmd="$(mise_bin)" || {
    error "mise is missing"
    return 127
  }

  write_capability_project
  probe_modes "${mise_cmd}"
  probe_conflicts "${mise_cmd}"
  probe_literal_sources "${mise_cmd}"
}

main "$@"
