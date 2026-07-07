#!/usr/bin/env bash
# paseo.sh — load the paseo daemon LaunchAgent so the phone can reach it.
#
# paseo (https://paseo.sh) lets the phone/web app drive local coding agents
# (Claude Code, Codex, pi) that already live on this Mac. The CLI is a mise tool
# (npm:@getpaseo/cli); the always-on daemon is a tracked LaunchAgent deployed by
# `mise dotfiles apply` to ~/Library/LaunchAgents/sh.paseo.daemon.plist. This
# script bootstraps that agent into the login session so the daemon starts now
# and again on every login. It is idempotent and never needs sudo (user agent).
#
# Pairing is one-time and interactive: open the paseo app on your phone, add this
# Mac's daemon at http://<tailscale-ip>:6767, and approve. Keeping the bind on the
# tailnet (see PASEO_LISTEN in the plist) means nothing is exposed publicly.
#
# Guarded to a no-op off macOS and skippable via DOTFILES_SKIP_PASEO=1. Wired into
# staged setup as an optional step; manage it any time with `just paseo`.
#
# Modes:
#   (default)  Load (and (re)start) the paseo daemon LaunchAgent.
#   --status   Report the agent state and how to connect. No changes.
#   --remove   Unload the LaunchAgent.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly LABEL="sh.paseo.daemon"
readonly PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
readonly PORT="6767"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

MODE="load"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status | --check) MODE="status" ;;
    --remove | --unload) MODE="remove" ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

uid="$(id -u)"
readonly DOMAIN="gui/${uid}"

agent_loaded() {
  launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1
}

print_connect_hint() {
  local addr=""
  if command -v tailscale >/dev/null 2>&1; then
    addr="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
  fi
  [[ -n "${addr}" ]] || addr="$(scutil --get LocalHostName 2>/dev/null).local"
  log "Connect from the paseo app on your phone: http://${addr}:${PORT}"
}

main() {
  if [[ -n "${DOTFILES_SKIP_PASEO:-}" ]]; then
    log "Skipping paseo daemon setup (DOTFILES_SKIP_PASEO is set)"
    return 0
  fi

  # LaunchAgents are a macOS concept; no-op elsewhere for a future Linux profile.
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  case "${MODE}" in
    status)
      if agent_loaded; then
        log "paseo daemon LaunchAgent is loaded (${LABEL})"
        print_connect_hint
        log "Logs: ${HOME}/Library/Logs/paseo.daemon.log"
      else
        log "paseo daemon LaunchAgent is NOT loaded (load it with: just paseo)"
      fi
      return 0
      ;;
    remove)
      log "Unloading the paseo daemon LaunchAgent"
      launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
      log "Unloaded. Re-run without --remove to restore."
      return 0
      ;;
  esac

  # load
  if [[ ! -f "${PLIST}" ]]; then
    warn "LaunchAgent not found at ${PLIST}; run 'mise dotfiles apply' first"
    return 0
  fi

  if ! command -v paseo >/dev/null 2>&1 && [[ ! -x "${HOME}/.local/share/mise/shims/paseo" ]]; then
    warn "paseo CLI not found yet; ensure mise installed npm:@getpaseo/cli (install:common:mise)"
    return 0
  fi

  if agent_loaded; then
    log "paseo daemon already loaded; restarting it"
    launchctl kickstart -k "${DOMAIN}/${LABEL}" 2>/dev/null || true
  else
    log "Loading the paseo daemon LaunchAgent"
    if ! launchctl bootstrap "${DOMAIN}" "${PLIST}" 2>/dev/null; then
      warn "Could not bootstrap ${LABEL} into ${DOMAIN}."
      warn "This needs an active login (GUI) session; run 'just paseo' from a console login."
      return 0
    fi
    launchctl enable "${DOMAIN}/${LABEL}" 2>/dev/null || true
  fi

  log "paseo daemon is running (listening on :${PORT})."
  print_connect_hint
  log "First time: pair by adding that URL in the paseo phone app, then approve."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
