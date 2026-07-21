#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

MODE="apply"

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/claude-skill-links.sh [--check]

Expose managed ~/.agents/skills entries to Claude without replacing the
host-owned ~/.claude/skills directory or its plugin/local-only entries.

Options:
  --check   Report missing or stale managed links without changing them.
  -h        Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | --plan) MODE="check" ;;
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

readonly SOURCE_ROOT="${DOTFILES_ROOT}/target/home/.agents/skills"
readonly TARGET_ROOT="${HOME}/.claude/skills"
CHANGES=0

managed_link_for_name() {
  local raw="$1" name="$2"
  case "${raw}" in
    "../../.agents/skills/${name}" | "${HOME}/.agents/skills/${name}" | "${SOURCE_ROOT}/${name}") return 0 ;;
    *) return 1 ;;
  esac
}

mark_change() {
  CHANGES=$((CHANGES + 1))
}

link_resolves_to() {
  local link_path="$1" raw="$2" expected_path="$3" actual_resolved expected_resolved
  if [[ "${raw}" == /* ]]; then
    actual_resolved="$(cd -- "$(dirname -- "${raw}")" && pwd -P)/$(basename -- "${raw}")"
  else
    actual_resolved="$(cd -- "$(dirname -- "${link_path}")/$(dirname -- "${raw}")" && pwd -P)/$(basename -- "${raw}")"
  fi
  expected_resolved="$(cd -- "$(dirname -- "${expected_path}")" && pwd -P)/$(basename -- "${expected_path}")"

  [[ "${actual_resolved}" == "${expected_resolved}" ]]
}

ensure_target_directory() {
  if [[ -L "${TARGET_ROOT}" ]]; then
    local raw
    raw="$(readlink "${TARGET_ROOT}")"
    if ! link_resolves_to "${TARGET_ROOT}" "${raw}" "${SOURCE_ROOT}" \
      && ! link_resolves_to "${TARGET_ROOT}" "${raw}" "${HOME}/.agents/skills"; then
      error "Claude skills is a host-owned directory symlink; refusing to replace it: ${TARGET_ROOT} -> ${raw}"
      return 1
    fi

    mark_change
    if [[ "${MODE}" == "check" ]]; then
      info "Claude skills: would replace the whole-directory symlink with a real directory"
      return
    fi
    rm -- "${TARGET_ROOT}"
    mkdir -p "${TARGET_ROOT}"
    info "Claude skills: replaced the whole-directory symlink with a host-owned directory"
    return
  fi

  if [[ -e "${TARGET_ROOT}" && ! -d "${TARGET_ROOT}" ]]; then
    error "Claude skills target exists but is not a directory: ${TARGET_ROOT}"
    return 1
  fi

  if [[ ! -d "${TARGET_ROOT}" ]]; then
    mark_change
    if [[ "${MODE}" == "check" ]]; then
      info "Claude skills: would create ${TARGET_ROOT}"
    else
      mkdir -p "${TARGET_ROOT}"
      info "Claude skills: created ${TARGET_ROOT}"
    fi
  fi
}

sync_managed_links() {
  local skill_file source_path name target_path desired_link raw

  while IFS= read -r skill_file; do
    source_path="$(dirname -- "${skill_file}")"
    name="$(basename -- "${source_path}")"
    target_path="${TARGET_ROOT}/${name}"
    desired_link="../../.agents/skills/${name}"

    if [[ -L "${target_path}" ]]; then
      raw="$(readlink "${target_path}")"
      if [[ "${raw}" == "${desired_link}" ]]; then
        continue
      fi

      if ! managed_link_for_name "${raw}" "${name}"; then
        info "Claude skills: preserving host-owned symlink ${name} -> ${raw}"
        continue
      fi

      if link_resolves_to "${target_path}" "${raw}" "${source_path}"; then
        continue
      fi

      mark_change
      if [[ "${MODE}" == "check" ]]; then
        info "Claude skills: would repair managed link ${name}"
      else
        rm -- "${target_path}"
        ln -s "${desired_link}" "${target_path}"
        info "Claude skills: repaired managed link ${name}"
      fi
      continue
    fi

    if [[ -e "${target_path}" ]]; then
      info "Claude skills: preserving host-owned entry ${name}"
      continue
    fi

    mark_change
    if [[ "${MODE}" == "check" ]]; then
      info "Claude skills: would link managed skill ${name}"
    else
      ln -s "${desired_link}" "${target_path}"
      info "Claude skills: linked managed skill ${name}"
    fi
  done < <(find "${SOURCE_ROOT}" -mindepth 2 -maxdepth 2 -name SKILL.md -type f | sort)
}

remove_stale_managed_links() {
  local target_path name raw

  [[ -d "${TARGET_ROOT}" && ! -L "${TARGET_ROOT}" ]] || return 0

  while IFS= read -r target_path; do
    name="$(basename -- "${target_path}")"
    [[ -f "${SOURCE_ROOT}/${name}/SKILL.md" ]] && continue

    raw="$(readlink "${target_path}")"
    managed_link_for_name "${raw}" "${name}" || continue

    mark_change
    if [[ "${MODE}" == "check" ]]; then
      info "Claude skills: would remove stale managed link ${name}"
    else
      rm -- "${target_path}"
      info "Claude skills: removed stale managed link ${name}"
    fi
  done < <(find "${TARGET_ROOT}" -mindepth 1 -maxdepth 1 -type l | sort)
}

main() {
  [[ -d "${SOURCE_ROOT}" ]] || {
    error "managed skills source is missing: ${SOURCE_ROOT}"
    return 1
  }

  ensure_target_directory
  if [[ "${MODE}" == "check" && ! -d "${TARGET_ROOT}" ]]; then
    return 1
  fi

  sync_managed_links
  remove_stale_managed_links

  if [[ "${MODE}" == "check" && "${CHANGES}" -gt 0 ]]; then
    warn "Claude skills: ${CHANGES} managed link change(s) pending"
    return 1
  fi

  info "Claude skills: managed links are current; host-owned entries were preserved"
}

main
