#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

is_non_interactive() {
  [[ "${CI:-}" == "true" || ! -t 0 ]]
}

homebrew_command() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif command -v brew >/dev/null 2>&1; then
    command -v brew
  fi
}

install_homebrew() {
  if homebrew_command >/dev/null; then
    log "Homebrew already installed"
    return
  fi

  log "Installing Homebrew"
  if is_non_interactive; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"
  else
    /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"
  fi
}

activate_homebrew() {
  local brew_cmd
  brew_cmd="$(homebrew_command || true)"

  if [[ -z "${brew_cmd}" ]]; then
    die "Homebrew installation finished, but brew is still unavailable"
  fi

  eval "$("${brew_cmd}" shellenv)"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  install_homebrew
  activate_homebrew
  brew analytics off >/dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
