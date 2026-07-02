#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

readonly MIRROR_PAIRS=(
  "home/dot_zshenv|target/home/.zshenv"
  "home/dot_zshrc|target/home/.zshrc"
  "home/dot_handy/settings_store.json|target/home/.handy/settings_store.json"
  "home/dot_local/bin/executable_coffee|target/home/.local/bin/coffee"
  "home/dot_uv/uv.toml|target/home/.uv/uv.toml"
  "home/dot_config/ccstatusline/settings.json|target/home/.config/ccstatusline/settings.json"
  "home/dot_config/exact_fish/config.fish|target/home/.config/fish/config.fish"
  "home/dot_config/exact_fish/exact_conf.d/00-paths.fish|target/home/.config/fish/conf.d/00-paths.fish"
  "home/dot_config/exact_fish/exact_conf.d/brew.fish|target/home/.config/fish/conf.d/brew.fish"
  "home/dot_config/exact_fish/exact_conf.d/mise.fish|target/home/.config/fish/conf.d/mise.fish"
  "home/dot_config/exact_fish/exact_conf.d/ripgrep.fish|target/home/.config/fish/conf.d/ripgrep.fish"
  "home/dot_config/exact_fish/exact_conf.d/starship.fish|target/home/.config/fish/conf.d/starship.fish"
  "home/dot_config/exact_fish/exact_conf.d/uv.env.fish|target/home/.config/fish/conf.d/uv.env.fish"
  "home/dot_config/exact_fish/exact_functions/_node_global_install_blocked.fish|target/home/.config/fish/functions/_node_global_install_blocked.fish"
  "home/dot_config/exact_fish/exact_functions/ct.fish|target/home/.config/fish/functions/ct.fish"
  "home/dot_config/exact_fish/exact_functions/gbda.fish|target/home/.config/fish/functions/gbda.fish"
  "home/dot_config/exact_fish/exact_functions/gm.fish|target/home/.config/fish/functions/gm.fish"
  "home/dot_config/exact_fish/exact_functions/ls.fish|target/home/.config/fish/functions/ls.fish"
  "home/dot_config/exact_fish/exact_functions/npm.fish|target/home/.config/fish/functions/npm.fish"
  "home/dot_config/exact_fish/exact_functions/p.fish|target/home/.config/fish/functions/p.fish"
  "home/dot_config/exact_fish/exact_functions/pb.fish|target/home/.config/fish/functions/pb.fish"
  "home/dot_config/exact_fish/exact_functions/pbc.fish|target/home/.config/fish/functions/pbc.fish"
  "home/dot_config/exact_fish/exact_functions/pbp.fish|target/home/.config/fish/functions/pbp.fish"
  "home/dot_config/exact_fish/exact_functions/pnpm.fish|target/home/.config/fish/functions/pnpm.fish"
  "home/dot_config/exact_fish/exact_functions/pt.fish|target/home/.config/fish/functions/pt.fish"
  "home/dot_config/exact_fish/exact_functions/tempd.fish|target/home/.config/fish/functions/tempd.fish"
  "home/dot_config/exact_fish/exact_functions/trash.fish|target/home/.config/fish/functions/trash.fish"
  "home/dot_config/exact_ghostty/config|target/home/.config/ghostty/config"
  "home/dot_config/exact_zsh/exact_aliases.d/clipboard.zsh|target/home/.config/zsh/aliases.d/clipboard.zsh"
  "home/dot_config/exact_zsh/exact_aliases.d/coffee.zsh|target/home/.config/zsh/aliases.d/coffee.zsh"
  "home/dot_config/exact_zsh/exact_aliases.d/gm.zsh|target/home/.config/zsh/aliases.d/gm.zsh"
  "home/dot_config/exact_zsh/exact_aliases.d/ls.zsh|target/home/.config/zsh/aliases.d/ls.zsh"
  "home/dot_config/exact_zsh/exact_aliases.d/npm-guard.zsh|target/home/.config/zsh/aliases.d/npm-guard.zsh"
  "home/dot_config/exact_zsh/exact_aliases.d/pnpm.zsh|target/home/.config/zsh/aliases.d/pnpm.zsh"
  "home/dot_config/exact_zsh/exact_functions/gbda|target/home/.config/zsh/functions/gbda"
  "home/dot_config/exact_zsh/exact_functions/tempd|target/home/.config/zsh/functions/tempd"
  "home/dot_config/exact_zsh/exact_functions/trash|target/home/.config/zsh/functions/trash"
  "home/dot_config/exact_zsh/exact_session.d/tmux.zsh|target/home/.config/zsh/session.d/tmux.zsh"
  "home/dot_config/exact_zsh/plugins.zsh|target/home/.config/zsh/plugins.zsh"
  "home/dot_config/ghui/config.json|target/home/.config/ghui/config.json"
  "home/dot_config/hunk/config.toml|target/home/.config/hunk/config.toml"
  "home/dot_config/nvim/dot_gitignore|target/home/.config/nvim/.gitignore"
  "home/dot_config/nvim/dot_neoconf.json|target/home/.config/nvim/.neoconf.json"
  "home/dot_config/nvim/init.lua|target/home/.config/nvim/init.lua"
  "home/dot_config/nvim/lazyvim.json|target/home/.config/nvim/lazyvim.json"
  "home/dot_config/nvim/lua/config/autocmds.lua|target/home/.config/nvim/lua/config/autocmds.lua"
  "home/dot_config/nvim/lua/config/keymaps.lua|target/home/.config/nvim/lua/config/keymaps.lua"
  "home/dot_config/nvim/lua/config/lazy.lua|target/home/.config/nvim/lua/config/lazy.lua"
  "home/dot_config/nvim/lua/config/options.lua|target/home/.config/nvim/lua/config/options.lua"
  "home/dot_config/nvim/lua/plugins/colorscheme.lua|target/home/.config/nvim/lua/plugins/colorscheme.lua"
  "home/dot_config/nvim/lua/plugins/diffview.lua|target/home/.config/nvim/lua/plugins/diffview.lua"
  "home/dot_config/nvim/lua/plugins/languages.lua|target/home/.config/nvim/lua/plugins/languages.lua"
  "home/dot_config/nvim/stylua.toml|target/home/.config/nvim/stylua.toml"
  "home/dot_config/ripgrep/config|target/home/.config/ripgrep/config"
  "home/dot_config/starship.toml|target/home/.config/starship.toml"
  "home/dot_config/tmux/tmux.conf|target/home/.config/tmux/tmux.conf"
)

failures=0

pass() {
  printf 'ok: %s\n' "$*"
}

fail() {
  failures=$((failures + 1))
  printf 'fail: %s\n' "$*" >&2
}

check_pair() {
  local pair="$1"
  local source_rel
  local target_rel
  local source_path
  local target_path

  IFS='|' read -r source_rel target_rel <<<"${pair}"
  source_path="${DOTFILES_ROOT}/${source_rel}"
  target_path="${DOTFILES_ROOT}/${target_rel}"

  if [[ ! -f "${source_path}" ]]; then
    fail "missing source: ${source_rel}"
    return
  fi

  if [[ ! -f "${target_path}" ]]; then
    fail "missing mirror: ${target_rel}"
    return
  fi

  if cmp -s "${source_path}" "${target_path}"; then
    pass "${target_rel} mirrors ${source_rel}"
  else
    fail "${target_rel} differs from ${source_rel}"
  fi
}

main() {
  local pair
  for pair in "${MIRROR_PAIRS[@]}"; do
    check_pair "${pair}"
  done

  if ((failures > 0)); then
    return 1
  fi
}

main "$@"
