#!/usr/bin/env bash
# Exercise the same persisted selection used by a login shell and maintenance.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${SCRIPT_DIR}/lib.sh"

tmp="$(mktemp -d)"
trap 'rm -rf -- "${tmp}"' EXIT

check_tools() {
  local selection="$1"
  shift
  printf '%s\n' ${selection} >"${HOME}/.config/dotfiles/profile"
  run_source_mise ls --current --json >"${tmp}/tools.json"
  python3 - "${tmp}/tools.json" "${selection}" "$@" <<'PY'
import json
import sys
from pathlib import Path

tools = json.loads(Path(sys.argv[1]).read_text())
for item in sys.argv[3:]:
    present = not item.startswith("!")
    name = item.lstrip("!")
    if (name in tools) != present:
        raise SystemExit(f"{sys.argv[2]}: expected {name} to be {'active' if present else 'inactive'}")
PY
}

# Run the public bootstrap against the disposable home. Keep its real file
# deployment and persistence stages, omitting system installers and services.
activate_work_profile() {
  local checkout="${HOME}/work/me/.dotfiles"
  mkdir -p "${checkout}/scripts/dotfiles" "${checkout}/install/common"
  ln -s "${DOTFILES_ROOT}/setup.sh" "${checkout}/setup.sh"
  ln -s "${DOTFILES_ROOT}/mise.toml" "${checkout}/mise.toml"
  ln -s "${DOTFILES_ROOT}/target" "${checkout}/target"
  ln -s "${DOTFILES_ROOT}/install/common/mise.sh" "${checkout}/install/common/mise.sh"
  cat >"${checkout}/scripts/dotfiles/mise-setup-staged.sh" <<'RUNNER'
#!/usr/bin/env bash
exec bash "${DOTFILES}/scripts/dotfiles/mise-setup-staged.sh" --only mise:bootstrap:dotfiles:apply "$@"
RUNNER
  mkdir -p "${HOME}/.local/bin"
  cp "$(mise_bin)" "${HOME}/.local/bin/mise"
  CI=true MISE_INSTALL_PATH="${HOME}/.local/bin/mise" DOTFILES="${DOTFILES_ROOT}"     bash "${checkout}/setup.sh" --profile work --with go
}

check_profiles() {
  unset DOTFILES_SELECTION DOTFILES_MIGRATE_IDENTITY DOTFILES_MIGRATE_PASEO
  mkdir -p "${HOME}/.config/dotfiles" "${HOME}/.config/git" "${HOME}/.ssh" \
    "${HOME}/.pi/agent/extensions" "${HOME}/.config/systemd/user" "${tmp}/project"
  local file="${HOME}/.config/dotfiles/profile" selector="${DOTFILES_MISE_DIR}/dotfiles-profile.sh"
  [[ "$(bash "${selector}" profile)" == full ]]
  # After the first pull on an existing workstation only the original config and lock links exist.
  mkdir -p "${HOME}/.config/mise"
  ln -s "${DOTFILES_MISE_CONFIG}" "${HOME}/.config/mise/config.toml"
  ln -s "${DOTFILES_MISE_DIR}/mise.lock" "${HOME}/.config/mise/mise.lock"
  printf 'work\ngo\n' >"${file}"
  (cd "${tmp}" && "$(mise_bin)" ls --current --json) >"${tmp}/legacy.json"
  python3 - "${tmp}/legacy.json" <<'PYTHON'
import json, sys
with open(sys.argv[1]) as stream:
    tools = json.load(stream)
assert "go" in tools and "npm:pnpm" in tools and "rust" not in tools
PYTHON
  check_tools essentials node npm:@openai/codex npm:@getpaseo/cli github:earendil-works/pi '!npm:pnpm' '!go' '!rust'
  check_tools work node npm:pnpm '!go' '!rust' '!pipx:huggingface_hub'
  check_tools 'work system-engineering' rust npm:pnpm '!go' '!github:agentstation/vhs'
  check_tools full rust go pipx:huggingface_hub github:agentstation/vhs
  check_tools 'work go' node npm:pnpm go '!rust' '!pipx:huggingface_hub' '!github:agentstation/vhs'

  printf 'Host work-vm\n  User developer\n' >"${HOME}/.ssh/config"
  printf '[user]\n  name = Work Developer\n' >"${HOME}/.config/git/config"
  printf 'host extension\n' >"${HOME}/.pi/agent/extensions/exe-dev.ts"
  printf '[Unit]\nDescription=Existing enrollment\n' >"${HOME}/.config/systemd/user/paseo.service"
  mkdir -p "${HOME}/.agents" "${HOME}/host-instructions"
  printf 'Use the host instructions.\n' >"${HOME}/host-instructions/Shelley.md"
  ln -s ../host-instructions/Shelley.md "${HOME}/.agents/AGENTS.md"
  cp "${file}" "${tmp}/saved"
  "${SCRIPT_DIR}/mise-setup-staged.sh" --plan --profile essentials >/dev/null
  if "${SCRIPT_DIR}/mise-setup-staged.sh" --plan --profile work --with nonexistent >"${tmp}/invalid" 2>&1; then
    error "setup preview accepted an unknown bundle"
    return 1
  fi
  grep -Fq "unknown bundle 'nonexistent'" "${tmp}/invalid"
  cmp "${file}" "${tmp}/saved"
  "${SCRIPT_DIR}/dotfiles.sh" apply --dry-run >"${tmp}/preview" 2>&1
  grep -Fq '.agents/AGENTS.md' "${tmp}/preview"
  [[ ! -e "${HOME}/.zprofile" && ! -e "${HOME}/.agents/skills" ]]
  ln -s host-instructions/Shelley.md "${HOME}/.zshrc"
  if "${SCRIPT_DIR}/dotfiles.sh" apply --yes >"${tmp}/link-conflict" 2>&1; then
    error "work apply replaced a host-owned shell link"
    return 1
  fi
  grep -Fq 'migrate the differing links' "${tmp}/link-conflict"
  [[ "$(readlink "${HOME}/.zshrc")" == host-instructions/Shelley.md && ! -e "${HOME}/.zprofile" ]]
  rm "${HOME}/.zshrc"
  rm "${file}"
  activate_work_profile >/dev/null
  cmp "${tmp}/saved" "${file}"
  [[ "$(bash "${selector}" bundles)" == 'essentials web go' ]]
  [[ -f "${HOME}/.zprofile" && -e "${HOME}/.agents/skills/create-cli/SKILL.md" ]]
  [[ ! -e "${HOME}/.local/bin/rust-cache-maintenance" && ! -L "${HOME}/.local/bin/rust-cache-maintenance" ]]
  [[ ! -e "${HOME}/.local/share/lean4-skills" && ! -e "${HOME}/.local/bin/coffee" ]]
  [[ ! -e "${HOME}/.local/share/qBittorrent" && ! -e "${HOME}/Library/Application Support/qBittorrent" ]]
  grep -Fxq '  User developer' "${HOME}/.ssh/config"
  grep -Fxq '  name = Work Developer' "${HOME}/.config/git/config"
  [[ "$(readlink "${HOME}/.agents/AGENTS.md")" == ../host-instructions/Shelley.md ]]
  grep -Fxq 'host extension' "${HOME}/.pi/agent/extensions/exe-dev.ts"
  grep -Fxq 'Description=Existing enrollment' "${HOME}/.config/systemd/user/paseo.service"

  if is_linux; then
    rm "${HOME}/.config/systemd/user/paseo.service"
    ln -s "${DOTFILES_ROOT}/target/home/.config/systemd/user/paseo.service" "${HOME}/.config/systemd/user/paseo.service"
    "${SCRIPT_DIR}/dotfiles.sh" envs >"${tmp}/unit-envs"
    ! grep -Fxq df-paseo-linux "${tmp}/unit-envs" || return 1
  fi

  printf '[tools]\nnode = "26"\n' >"${tmp}/project/mise.toml"
  printf '[tools]\nnode = "24"\n' >"${tmp}/project/mise.ci.toml"
  # This independent project pins Node without maintaining a project lock.
  MISE_LOCKED=0 MISE_TRUSTED_CONFIG_PATHS="${tmp}/project:${DOTFILES_ROOT}:${HOME}/.config/mise" \
    "$(mise_bin)" -C "${tmp}/project" -E ci ls --current --json node >"${tmp}/node.json"
  python3 - "${tmp}/node.json" <<'PYTHON'
import json
import sys
from pathlib import Path

versions = json.loads(Path(sys.argv[1]).read_text())
assert len(versions) == 1 and versions[0]["requested_version"] == "24", versions
PYTHON
  [[ "$(bash "${selector}" bundles)" == 'essentials web go' ]]
  cmp "${file}" "${tmp}/saved"
  info "profile composition, project environment and existing work home passed"
}

MISE_LOCKED=1 MISE_AUTO_INSTALL=0 MISE_NOT_FOUND_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0 \
  HOME="${tmp}/home" XDG_CONFIG_HOME="${tmp}/home/.config" XDG_CACHE_HOME="${tmp}/cache" \
  XDG_STATE_HOME="${tmp}/state" XDG_DATA_HOME="${tmp}/data" check_profiles
