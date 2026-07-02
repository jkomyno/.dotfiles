#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

readonly MIRROR_PAIRS=(
  "home/dot_zshenv|target/home/.zshenv"
  "home/dot_zshrc|target/home/.zshrc"
  "home/dot_config/ccstatusline/settings.json|target/home/.config/ccstatusline/settings.json"
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
