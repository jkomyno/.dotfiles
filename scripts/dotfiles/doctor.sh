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
    ".chezmoiroot"
    "mise.toml"
    "setup.sh"
    "README.md"
    "home/.chezmoiignore"
    "home/dot_zprofile.tmpl"
    "home/dot_mise/config.toml"
    "home/dot_mise/mise.lock"
    "home/dot_claude/settings.json.tmpl"
    "home/dot_config/exact_mise/symlink_config.toml.tmpl"
    "home/dot_config/exact_mise/symlink_mise.lock.tmpl"
    "target/home/.zprofile"
    "target/home/.zshenv"
    "target/home/.zshrc"
    "target/home/.agents/AGENTS.md"
    "target/home/.claude/CLAUDE.md"
    "target/home/.claude/hooks/block-claude-attribution.sh"
    "target/home/.claude/hooks/rtk-rewrite.sh"
    "target/home/.claude/settings.json"
    "target/home/.codex/AGENTS.md"
    "target/home/.codex/config.toml"
    "target/home/.handy/settings_store.json"
    "target/home/.local/bin/coffee"
    "target/home/.pi/agent/settings.json"
    "target/home/.uv/uv.toml"
    "target/home/.config/ccstatusline/settings.json"
    "target/home/.config/fish/config.fish"
    "target/home/.config/fish/conf.d/00-paths.fish"
    "target/home/.config/fish/conf.d/brew.fish"
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
    "target/home/.config/git/attributes"
    "target/home/.config/git/config"
    "target/home/.config/git/config-composio"
    "target/home/.config/git/ignore"
    "target/home/.config/ghostty/config"
    "target/home/.config/ghui/config.json"
    "target/home/.config/hunk/config.toml"
    "target/home/.config/mise/config.toml"
    "target/home/.config/mise/mise.lock"
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
    "target/home/.config/nvim/stylua.toml"
    "target/home/.config/ripgrep/config"
    "target/home/.config/starship.toml"
    "target/home/.config/tmux/tmux.conf"
    "target/home/.config/zsh/aliases.d/clipboard.zsh"
    "target/home/.config/zsh/aliases.d/coffee.zsh"
    "target/home/.config/zsh/aliases.d/gm.zsh"
    "target/home/.config/zsh/aliases.d/ls.zsh"
    "target/home/.config/zsh/aliases.d/npm-guard.zsh"
    "target/home/.config/zsh/aliases.d/pnpm.zsh"
    "target/home/.config/zsh/functions/gbda"
    "target/home/.config/zsh/functions/tempd"
    "target/home/.config/zsh/functions/trash"
    "target/home/.config/zsh/plugins.zsh"
    "target/home/.config/zsh/session.d/tmux.zsh"
    "scripts/dotfiles/mise-dotfiles-capabilities.sh"
    "scripts/dotfiles/mise-dotfiles-check.sh"
    "scripts/dotfiles/mise-dotfiles-mirror-check.sh"
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
      find "${DOTFILES_ROOT}/install" "${DOTFILES_ROOT}/scripts" "${DOTFILES_ROOT}/tasks" -type f -name '*.sh' 2>/dev/null
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
  local symlink_template
  for symlink_template in \
    "${DOTFILES_ROOT}/home/dot_config/exact_mise/symlink_config.toml.tmpl" \
    "${DOTFILES_ROOT}/home/dot_config/exact_mise/symlink_mise.lock.tmpl"; do
    if run_chezmoi_source execute-template < "${symlink_template}" >/dev/null; then
      pass "${symlink_template#"${DOTFILES_ROOT}"/} renders"
    else
      hard_fail "${symlink_template#"${DOTFILES_ROOT}"/} failed to render"
    fi
  done

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

check_mise_dotfiles_mirrors() {
  if "${SCRIPT_DIR}/mise-dotfiles-mirror-check.sh" >/dev/null; then
    pass "target-shaped mise dotfiles mirrors match current sources"
  else
    hard_fail "target-shaped mise dotfiles mirrors differ from current sources"
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
  check_mise_dotfiles_mirrors
  check_packages

  printf '\nsummary: failures=%s warnings=%s\n' "${failures}" "${warnings}"
  if ((failures > 0)); then
    return 1
  fi
}

main "$@"
