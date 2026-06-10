#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

has_command_line_tools() {
  xcode-select -p >/dev/null 2>&1
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

install_command_line_tools() {
  if has_command_line_tools; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  if [[ "${CI:-}" == "true" ]] || ! has_tty; then
    die "Xcode Command Line Tools missing. Run 'xcode-select --install', finish the installer, then rerun setup."
  fi

  log "Opening Xcode Command Line Tools installer"
  xcode-select --install || true

  printf 'Finish the Apple installer, then press Return to continue.' >/dev/tty
  IFS= read -r _ </dev/tty

  has_command_line_tools || die "Xcode Command Line Tools still unavailable after installer"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  install_command_line_tools
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
