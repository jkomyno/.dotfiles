#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
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
    ".miserc.toml"
    "mise.toml"
    "mise.linux.toml"
    "mise.macos.toml"
    "setup.sh"
    "README.md"
    "THIRD-PARTY-NOTICES.md"
    "target/home/.zprofile"
    "target/home/.zshenv"
    "target/home/.zshrc"
    "target/home/.agents/AGENTS.md"
    "target/home/.agents/skills/sync-skills/SKILL.md"
    "target/home/.claude/CLAUDE.md"
    "target/home/.claude/hooks/block-claude-attribution.sh"
    "target/home/.claude/hooks/rtk-rewrite.sh"
    "target/home/.claude/settings.json"
    "target/home/.codex/AGENTS.md"
    "target/home/.codex/config.toml"
    "target/home/.handy/settings_store.json"
    "target/home/.local/bin/coffee"
    "target/home/.local/bin/clipboard-copy"
    "target/home/.local/bin/clipboard-paste"
    "target/home/.pi/agent/settings.json"
    "target/home/.pi/agent/extensions/agentmemory/index.ts"
    "target/home/.pi/agent/extensions/agentmemory/security.ts"
    "target/home/.ssh/config"
    "target/home/.uv/uv.toml"
    "target/home/.config/ccstatusline/settings.json"
    "target/home/.config/fish/config.fish"
    "target/home/.config/fish/conf.d/00-paths.fish"
    "target/home/.config/fish/conf.d/nanobrew.fish"
    "target/home/.config/fish/conf.d/macos-apps.fish"
    "target/home/.config/fish/conf.d/mise.fish"
    "target/home/.config/fish/conf.d/ripgrep.fish"
    "target/home/.config/fish/conf.d/starship.fish"
    "target/home/.config/fish/conf.d/uv.env.fish"
    "target/home/.config/fish/functions/_node_global_install_blocked.fish"
    "target/home/.config/fish/functions/ct.fish"
    "target/home/.config/fish/functions/gbda.fish"
    "target/home/.config/fish/functions/gm.fish"
    "target/home/.config/fish/functions/ls.fish"
    "target/home/.config/fish/functions/npm.fish"
    "target/home/.config/fish/functions/p.fish"
    "target/home/.config/fish/functions/pb.fish"
    "target/home/.config/fish/functions/pbc.fish"
    "target/home/.config/fish/functions/pbp.fish"
    "target/home/.config/fish/functions/pnpm.fish"
    "target/home/.config/fish/functions/pt.fish"
    "target/home/.config/fish/functions/tempd.fish"
    "target/home/.config/fish/functions/trash.fish"
    "target/home/.config/gh/config.yml"
    "target/home/.config/git/attributes"
    "target/home/.config/git/config"
    "target/home/.config/git/config-composio"
    "target/home/.config/git/ignore"
    "target/home/.config/ghostty/config"
    "target/home/.config/ghui/config.json"
    "target/home/.config/hunk/config.toml"
    "target/home/.config/mise/config.toml"
    "target/home/.config/mise/config.linux.toml"
    "target/home/.config/mise/mise.lock"
    "target/home/.config/mise/mise.linux.lock"
    "target/home/.config/systemd/user/agentmemory.service"
    "target/home/.config/systemd/user/paseo.service"
    "target/home/.config/nvim/.gitignore"
    "target/home/.config/nvim/.neoconf.json"
    "target/home/.config/nvim/init.lua"
    "target/home/.config/nvim/lazyvim.json"
    "target/home/.config/nvim/lua/config/autocmds.lua"
    "target/home/.config/nvim/lua/config/keymaps.lua"
    "target/home/.config/nvim/lua/config/lazy.lua"
    "target/home/.config/nvim/lua/config/options.lua"
    "target/home/.config/nvim/lua/plugins/colorscheme.lua"
    "target/home/.config/nvim/lua/plugins/diffview.lua"
    "target/home/.config/nvim/lua/plugins/languages.lua"
    "target/home/.config/nvim/spell/custom.utf-8.add"
    "target/home/.config/nvim/stylua.toml"
    "target/home/.config/ripgrep/config"
    "target/home/.config/starship.toml"
    "target/home/.config/tmux/tmux.conf"
    "target/home/.config/zsh/aliases.d/clipboard.zsh"
    "target/home/.config/zsh/aliases.d/coffee.zsh"
    "target/home/.config/zsh/aliases.d/git-shortcuts.zsh"
    "target/home/.config/zsh/aliases.d/ls.zsh"
    "target/home/.config/zsh/aliases.d/npm-guard.zsh"
    "target/home/.config/zsh/aliases.d/pnpm.zsh"
    "target/home/.config/zsh/functions/gbda"
    "target/home/.config/zsh/functions/tempd"
    "target/home/.config/zsh/functions/trash"
    "target/home/.config/zsh/plugins.zsh"
    "target/home/.config/zsh/session.d/tmux.zsh"
    "scripts/dotfiles/mise-dotfiles-check.sh"
    "scripts/dotfiles/update-flow-check.sh"
    "scripts/dotfiles/claude-skill-links.sh"
    "scripts/dotfiles/mise-setup-staged.sh"
    "scripts/dotfiles/mise-setup-staged-smoke.sh"
    "scripts/dotfiles/mise-tasks-check.sh"
    "scripts/dotfiles/services-check.sh"
    "scripts/dotfiles/git-signing-check.sh"
    "install/macos/common/nanobrew-casks.Brewfile"
    "install/macos/common/nanobrew-formulae.Brewfile"
    "install/linux/common/packages.sh"
    "install/linux/common/login-shell.sh"
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

check_removed_home_tree_absent() {
  if [[ -e "${DOTFILES_ROOT}/home" || -L "${DOTFILES_ROOT}/home" ]]; then
    hard_fail "retired source tree still exists: home"
  else
    pass "retired source tree is absent"
  fi
}

check_agent_skill_files() {
  local source_entry
  local skill
  while IFS= read -r source_entry; do
    skill="${source_entry##*/}"
    if [[ -L "${source_entry}" ]]; then
      hard_fail "target/home/.agents/skills/${skill} must be a real directory, not a symlink"
    elif [[ ! -d "${source_entry}" ]]; then
      hard_fail "target/home/.agents/skills/${skill} is not a directory"
    elif [[ -f "${source_entry}/SKILL.md" ]]; then
      pass "target/home/.agents/skills/${skill}/SKILL.md exists"
    else
      hard_fail "target/home/.agents/skills/${skill}/SKILL.md is missing"
    fi
  done < <(find "${DOTFILES_ROOT}/target/home/.agents/skills" -maxdepth 1 -mindepth 1 -print | sort)
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
      find "${DOTFILES_ROOT}/install" "${DOTFILES_ROOT}/scripts" "${DOTFILES_ROOT}/tasks" -type f -name '*.sh' 2>/dev/null
    } | sort -u
  )
  pass "bash syntax checked for ${count} scripts"

  if have zsh; then
    local zsh_file
    local zsh_ok=true
    for zsh_file in \
      "${DOTFILES_ROOT}/target/home/.zshenv" \
      "${DOTFILES_ROOT}/target/home/.zshrc"; do
      if ! zsh -n "${zsh_file}"; then
        hard_fail "zsh syntax failed: ${zsh_file#"${DOTFILES_ROOT}/"}"
        zsh_ok=false
      fi
    done
    [[ "${zsh_ok}" == true ]] && pass "zsh syntax checked"
  else
    soft_fail "zsh syntax check skipped because zsh is missing"
  fi

  local fish_bin=""
  if is_linux && mise_bin >/dev/null 2>&1; then
    fish_bin="$(run_source_mise which fish 2>/dev/null || true)"
  elif have fish && fish --version >/dev/null 2>&1; then
    fish_bin="$(command -v fish)"
  fi

  if [[ -n "${fish_bin}" ]]; then
    local fish_files=()
    while IFS= read -r file; do
      fish_files+=("${file}")
    done < <(find "${DOTFILES_ROOT}/target/home/.config/fish" -type f -name '*.fish' | sort)
    if "${fish_bin}" -n "${fish_files[@]}"; then
      pass "fish syntax checked"
    else
      hard_fail "fish syntax failed"
    fi
  else
    soft_fail "fish syntax check skipped because fish is missing"
  fi
}

check_mise() {
  if ! mise_bin >/dev/null 2>&1; then
    soft_fail "mise is missing; setup.sh installs it before running staged setup"
    return
  fi

  pass "mise is available"
  if run_source_mise config ls --no-header >/dev/null; then
    pass "source mise config is loadable"
  else
    hard_fail "source mise config is not loadable"
  fi

  if run_source_mise_base lock --global --dry-run --platform "${DOTFILES_MISE_PLATFORMS}" --minimum-release-age "${DOTFILES_MISE_MINIMUM_RELEASE_AGE}" >/dev/null; then
    pass "source mise lock can be refreshed for ${DOTFILES_MISE_PLATFORMS}"
  else
    soft_fail "mise lock dry-run reported issues; rerun scripts/dotfiles/versions.sh for details"
  fi
}

check_platform_profile() {
  local configs
  configs="$(MISE_AUTO_ENV=true MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}" "$(mise_bin)" -C "${DOTFILES_ROOT}" config ls --no-header)"
  if is_linux; then
    grep -Eq '(^|/)mise\.linux\.toml[[:space:]]' <<<"${configs}" || hard_fail "Linux mise profile is not loaded"
    if grep -Eq '(^|/)mise\.macos\.toml[[:space:]]' <<<"${configs}"; then
      hard_fail "macOS mise profile loaded on Linux"
    else
      pass "only the Linux repository mise profile is active"
    fi

    if bash "${DOTFILES_ROOT}/install/linux/common/packages.sh" --dry-run >/dev/null; then
      pass "Linux apt bootstrap dry-run passed"
    else
      hard_fail "Linux apt bootstrap dry-run failed"
    fi
    if [[ -x /usr/bin/zsh ]]; then
      if bash "${DOTFILES_ROOT}/install/linux/common/login-shell.sh" --dry-run >/dev/null; then
        pass "Linux login-shell dry-run passed"
      else
        hard_fail "Linux login-shell dry-run failed"
      fi
    else
      soft_fail "Linux login-shell dry-run skipped until the package step installs zsh"
    fi
  elif is_macos; then
    grep -Eq '(^|/)mise\.macos\.toml[[:space:]]' <<<"${configs}" || hard_fail "macOS mise profile is not loaded"
    if grep -Eq '(^|/)mise\.linux\.toml[[:space:]]' <<<"${configs}"; then
      hard_fail "Linux mise profile loaded on macOS"
    else
      pass "only the macOS repository mise profile is active"
    fi
  fi

  if MISE_INSTALL_PATH="$(mise_bin)" bash "${DOTFILES_ROOT}/install/common/mise.sh" --dry-run >/dev/null; then
    pass "mise tool installation dry-run passed"
  else
    hard_fail "mise tool installation dry-run failed"
  fi
}

check_mise_tasks() {
  if ! mise_bin >/dev/null 2>&1; then
    soft_fail "mise task wrapper validation skipped because mise is missing"
    return
  fi

  if "${SCRIPT_DIR}/mise-tasks-check.sh" >/dev/null; then
    pass "mise task wrappers are valid"
  else
    hard_fail "mise task wrapper validation failed"
  fi
}

check_staged_setup_smoke() {
  if ! mise_bin >/dev/null 2>&1; then
    soft_fail "staged setup smoke test skipped because mise is missing"
    return
  fi

  local output
  if output="$("${SCRIPT_DIR}/mise-setup-staged-smoke.sh" 2>&1)"; then
    pass "staged setup smoke test passed"
  else
    printf '%s\n' "${output}" >&2
    hard_fail "staged setup smoke test failed"
  fi
}

check_services() {
  if "${SCRIPT_DIR}/services-check.sh" >/dev/null; then
    pass "portable user-service checks passed"
  else
    hard_fail "portable user-service checks failed"
  fi
}

check_git_signing_generator() {
  if "${SCRIPT_DIR}/git-signing-check.sh" >/dev/null; then
    pass "Git SSH signing generator is valid"
  else
    hard_fail "Git SSH signing generator validation failed"
  fi
}

check_auth() {
  # Authentication is a manual post-install step (browser OAuth / keyring
  # tokens that are never tracked), so an unauthenticated tool is a warning,
  # never a hard failure. A tool that is not installed yet is skipped silently.
  check_one_auth() {
    local tool="$1"
    shift
    if ! have "${tool}"; then
      return 0
    fi
    if "$@" >/dev/null 2>&1; then
      pass "${tool} is authenticated"
    else
      soft_fail "${tool} is not authenticated (run: just auth)"
    fi
  }

  check_one_auth gh gh auth status --hostname github.com
  check_one_auth codex codex login status
  # claude auth status exits 0 even when signed out; key off the loggedIn flag.
  if have claude; then
    if claude auth status 2>/dev/null | grep -q '"loggedIn": *true'; then
      pass "claude is authenticated"
    else
      soft_fail "claude is not authenticated (run: just auth)"
    fi
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
    check_command nb warn
  elif is_linux; then
    pass "supported Linux target detected"
  else
    soft_fail "unsupported OS for provisioning: $(os_name)"
  fi
}

main() {
  log "Running dotfiles doctor for ${DOTFILES_ROOT}"
  printf 'system: os=%s arch=%s\n' "$(os_name)" "$(uname -m)"

  check_required_files
  check_removed_home_tree_absent
  check_agent_skill_files
  check_git
  check_shell_syntax
  check_mise
  check_platform_profile
  check_mise_tasks
  check_staged_setup_smoke
  check_services
  check_git_signing_generator
  check_packages
  check_auth

  printf '\nsummary: failures=%s warnings=%s\n' "${failures}" "${warnings}"
  if ((failures > 0)); then
    return 1
  fi
}

main "$@"
