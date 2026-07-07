#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

# softwareupdate only lists the Command Line Tools while this on-demand marker
# exists. `xcode-select --install` also drops it; we recreate it if needed.
readonly CLT_IN_PROGRESS_MARKER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
# Upper bound for waiting on an asynchronous GUI install (~920MB download plus
# install). Generous so a real download over a slow link is never cut short;
# overridable for tests.
readonly CLT_WAIT_TIMEOUT="${CLT_WAIT_TIMEOUT:-1800}"
readonly CLT_WAIT_INTERVAL=10

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

can_sudo_noninteractive() {
  sudo -n true >/dev/null 2>&1
}

# Newest installable "Command Line Tools for Xcode" softwareupdate label, or
# empty if none is offered.
latest_clt_label() {
  [[ -e "${CLT_IN_PROGRESS_MARKER}" ]] || : >"${CLT_IN_PROGRESS_MARKER}" 2>/dev/null || true

  softwareupdate --list 2>/dev/null |
    grep 'Label:.*Command Line Tools' |
    sed -E 's/^.*Label: *//' |
    sort -V |
    tail -1
}

# Fully headless install: no GUI dialog and no /dev/tty prompt. Only attempted
# when sudo needs no password, which is the case during setup.sh (it primes a
# sudo keepalive). This avoids the interactive `read` that returned immediately
# under `mise run` over SSH and aborted before the install could finish.
install_command_line_tools_headless() {
  can_sudo_noninteractive || return 1

  local label
  label="$(latest_clt_label)" || true
  [[ -n "${label}" ]] || return 1

  log "Installing '${label}' via softwareupdate (headless)"
  local status=0
  sudo -n softwareupdate --install "${label}" --verbose || status=$?
  rm -f "${CLT_IN_PROGRESS_MARKER}" 2>/dev/null || true

  ((status == 0)) || return 1
  has_command_line_tools
}

# Wait for an asynchronous install (the on-screen GUI installer, or a background
# softwareupdate) to make the tools available. Replaces a single blocking
# `read </dev/tty`, which returned immediately under `mise run` over SSH and
# aborted the step while the installer was still running.
wait_for_command_line_tools() {
  local waited=0

  log "Waiting for Command Line Tools to finish installing"
  while ! has_command_line_tools; do
    if ((waited >= CLT_WAIT_TIMEOUT)); then
      die "Command Line Tools still unavailable after ${CLT_WAIT_TIMEOUT}s. Finish 'xcode-select --install', then rerun setup."
    fi
    sleep "${CLT_WAIT_INTERVAL}"
    waited=$((waited + CLT_WAIT_INTERVAL))
  done
}

install_command_line_tools() {
  if has_command_line_tools; then
    log "Xcode Command Line Tools already installed"
    return
  fi

  if install_command_line_tools_headless; then
    log "Xcode Command Line Tools installed"
    return
  fi

  if [[ "${CI:-}" == "true" ]]; then
    die "Xcode Command Line Tools missing. Run 'xcode-select --install', finish the installer, then rerun setup."
  fi

  log "Opening Xcode Command Line Tools installer; complete it on screen if prompted"
  xcode-select --install >/dev/null 2>&1 || true
  wait_for_command_line_tools
  log "Xcode Command Line Tools installed"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  install_command_line_tools
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
