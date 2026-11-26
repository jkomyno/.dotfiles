#!/usr/bin/env bash
# Translate the host selection to mise environments only for dotfile operations.
set -Eeuo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${script_dir}/lib.sh"
profile_resolve
os=linux
if is_macos; then os=macos; fi
envs=("${os}")
for bundle in ${DOTFILES_BUNDLES}; do
  for env_name in "df-${bundle}" "df-${bundle}-${os}"; do
    [[ ! -f "${DOTFILES_ROOT}/mise.${env_name}.toml" ]] || envs+=("${env_name}")
  done
done
if profile_identity; then envs+=(df-identity); fi
if profile_paseo; then envs+=("df-paseo-${os}"); fi
if [[ "${1:-}" == envs ]]; then printf '%s\n' "${envs[@]}"; exit; fi
profile_report
native() {
  local IFS=,
  MISE_CEILING_PATHS="$(dirname -- "${DOTFILES_ROOT}")" MISE_ENV="${envs[*]}" MISE_AUTO_ENV=false MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "$(mise_bin)" -C "${DOTFILES_ROOT}" bootstrap dotfiles "$@"
}
if [[ "${1:-}" != apply ]]; then native "$@"; exit; fi
shift
preview=false
targeted=false
force=false
for arg in "$@"; do
  case "${arg}" in --dry-run|-n) preview=true ;; --force|-f) force=true ;; --yes|-y) ;; -*) error "unsupported apply flag: ${arg}"; exit 2 ;; *) targeted=true ;; esac
done
if "${targeted}"; then native apply "$@"; exit; fi

agent_conflict=false
if ! bash "${script_dir}/claude-skill-links.sh" --plan; then
  "${preview}" || exit 1
  agent_conflict=true
fi
if [[ "${DOTFILES_PROFILE}" != full ]]; then
  if [[ " ${envs[*]} " != *" df-paseo-${os} "* ]]; then
    info "preserving existing Paseo unit; use DOTFILES_MIGRATE_PASEO=1 for a reviewed cutover"
  fi
  if [[ " ${envs[*]} " != *" df-identity "* ]]; then info "preserving host SSH and Git identities"; fi
  if [[ -d "${HOME}/.pi/agent/extensions" ]]; then
    for extension in "${HOME}"/.pi/agent/extensions/*; do
      [[ ! -e "${extension}" ]] || info "existing Pi extension: ${extension}"
    done
  fi
  # Native apply refuses differing files as a group. Exclude host-owned instruction
  # files so a VM can keep its enrollment and still receive the remaining mappings.
  targets="$(native status --json | python3 -c '
import json, os, sys
foreign_links = []
for entry in json.load(sys.stdin)["files"]:
    path = entry["target"]
    if path in ("~/.agents/AGENTS.md", "~/.claude/CLAUDE.md", "~/.codex/AGENTS.md", "~/.pi/agent/AGENTS.md") and entry["state"] == "differs":
        print("preserving host instructions: " + path, file=sys.stderr)
    else:
        if entry["state"] == "differs":
            print("review differing target: " + path, file=sys.stderr)
            if os.path.islink(os.path.expanduser(path)):
                foreign_links.append(path)
        print(path)
if foreign_links and sys.argv[1:] == ["false", "false"]:
    sys.exit("preserve or migrate the differing links before applying; use --force only on reviewed targets")
' "${preview}" "${force}")"
  [[ -n "${targets}" ]] || { error "no active dotfile mappings"; exit 1; }
  args=("$@")
  while IFS= read -r target; do args+=("${target}"); done <<<"${targets}"
  native apply "${args[@]}"
else
  native apply "$@"
fi
if "${preview}"; then
  ! "${agent_conflict}"
else
  bash "${script_dir}/claude-skill-links.sh"
fi
