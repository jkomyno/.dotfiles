#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

failures=0
warnings=0

pass() {
  printf 'ok: %s\n' "$*"
}

soft_fail() {
  warnings=$((warnings + 1))
  printf 'warn: %s\n' "$*" >&2
}

hard_fail() {
  failures=$((failures + 1))
  printf 'fail: %s\n' "$*" >&2
}

check_command() {
  local name="$1"
  local severity="${2:-warn}"
  if have "${name}"; then
    pass "${name} is available"
  elif [[ "${severity}" == "fail" ]]; then
    hard_fail "${name} is missing"
  else
    soft_fail "${name} is missing"
  fi
}

check_required_files() {
  local files=(
    ".chezmoiroot"
    "setup.sh"
    "README.md"
    "home/.chezmoiignore"
    "home/dot_mise/config.toml"
    "home/dot_mise/mise.lock"
    "home/dot_config/exact_mise/symlink_config.toml.tmpl"
    "install/macos/common/nanobrew-casks.Brewfile"
    "install/macos/common/nanobrew-formulae.Brewfile"
    "home/dot_agents/skills/exact_sync-skills/SKILL.md"
  )
  local file

  for file in "${files[@]}"; do
    if [[ -e "${DOTFILES_ROOT}/${file}" ]]; then
      pass "${file} exists"
    else
      hard_fail "${file} is missing"
    fi
  done
}

check_git() {
  if ! have git; then
    hard_fail "git is missing"
    return
  fi

  pass "git is available"
  if git -C "${DOTFILES_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    pass "repository is a git working tree"
  else
    hard_fail "repository is not a git working tree"
    return
  fi

  local status
  status="$(git -C "${DOTFILES_ROOT}" status --short)"
  if [[ -z "${status}" ]]; then
    pass "git worktree is clean"
  else
    soft_fail "git worktree has local changes"
    printf '%s\n' "${status}" >&2
  fi
}

check_shell_syntax() {
  if ! have bash; then
    hard_fail "bash is missing"
    return
  fi

  local file
  local count=0
  while IFS= read -r file; do
    count=$((count + 1))
    if ! env LC_ALL=C LANG=C bash -n "${file}"; then
      hard_fail "bash syntax failed: ${file#"${DOTFILES_ROOT}"/}"
    fi
  done < <(
    {
      printf '%s\n' "${DOTFILES_ROOT}/setup.sh"
      find "${DOTFILES_ROOT}/install" "${DOTFILES_ROOT}/scripts" -type f -name '*.sh' 2>/dev/null
    } | sort -u
  )
  pass "bash syntax checked for ${count} scripts"
}

check_chezmoi() {
  if ! chezmoi_bin >/dev/null 2>&1; then
    soft_fail "chezmoi is missing; setup.sh will install it on a fresh machine"
    return
  fi

  pass "chezmoi is available"
  if run_chezmoi_source execute-template < "${DOTFILES_ROOT}/home/dot_config/exact_mise/symlink_config.toml.tmpl" >/dev/null; then
    pass "mise symlink template renders"
  else
    hard_fail "mise symlink template failed to render"
  fi

  local tmpl tmp
  local rendered=0
  while IFS= read -r tmpl; do
    tmp="$(mktemp)"
    if run_chezmoi_source execute-template < "${tmpl}" > "${tmp}" && env LC_ALL=C LANG=C bash -n "${tmp}"; then
      rendered=$((rendered + 1))
    else
      hard_fail "rendered hook failed syntax check: ${tmpl#"${DOTFILES_ROOT}"/}"
    fi
    rm -f "${tmp}"
  done < <(find "${DOTFILES_ROOT}/home/.chezmoiscripts" -type f -name '*.tmpl' | sort)
  pass "rendered ${rendered} chezmoi hook templates"
}

check_mise() {
  if ! mise_bin >/dev/null 2>&1; then
    soft_fail "mise is missing; setup.sh installs it after chezmoi applies the managed config"
    return
  fi

  pass "mise is available"
  if run_source_mise config ls --no-header >/dev/null; then
    pass "source mise config is loadable"
  else
    hard_fail "source mise config is not loadable"
  fi

  if run_source_mise lock --dry-run --platform "${DOTFILES_MISE_PLATFORMS}" --minimum-release-age "${DOTFILES_MISE_MINIMUM_RELEASE_AGE}" >/dev/null; then
    pass "source mise lock can be refreshed for ${DOTFILES_MISE_PLATFORMS}"
  else
    soft_fail "mise lock dry-run reported issues; rerun scripts/dotfiles/versions.sh for details"
  fi
}

check_packages() {
  if "${SCRIPT_DIR}/packages.sh" --check-syntax >/dev/null; then
    pass "package bundles are valid and ownership is not duplicated"
  else
    hard_fail "package bundle validation failed"
  fi

  if is_macos; then
    if [[ "$(uname -m)" == "arm64" ]]; then
      pass "macOS arm64 target detected"
    else
      soft_fail "macOS target is $(uname -m); provisioning scripts currently support arm64 only"
    fi
    check_command brew warn
    check_command nb warn
  elif is_linux; then
    pass "Linux detected; macOS package/defaults hooks are skipped"
  else
    soft_fail "unsupported OS for provisioning: $(os_name)"
  fi
}

main() {
  log "Running dotfiles doctor for ${DOTFILES_ROOT}"
  printf 'system: os=%s arch=%s\n' "$(os_name)" "$(uname -m)"

  check_required_files
  check_git
  check_shell_syntax
  check_chezmoi
  check_mise
  check_packages

  printf '\nsummary: failures=%s warnings=%s\n' "${failures}" "${warnings}"
  if ((failures > 0)); then
    return 1
  fi
}

main "$@"
