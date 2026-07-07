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
# Pairing is one-time and interactive: run `just paseo --pair` for the QR/link, or
# open the paseo app on your phone, add this Mac's daemon at
# http://<tailscale-ip>:6767, and approve. The daemon binds the tailnet (see the
# plist's --listen), so nothing is exposed publicly.
#
# paseo is resolved through `mise exec npm:@getpaseo/cli` rather than a shim,
# because a `paseo` shim is not always generated (activate-mode machines), whereas
# `mise exec` always resolves an installed mise tool.
#
# Guarded to a no-op off macOS and skippable via DOTFILES_SKIP_PASEO=1. Wired into
# staged setup as an optional step; manage it any time with `just paseo`.
#
# Modes:
#   (default)  Load (and (re)start) the paseo daemon LaunchAgent.
#   --status   Report the agent state and daemon status. No changes.
#   --pair     Print the pairing QR/link for the phone app.
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
    --pair) MODE="pair" ;;
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
readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"

agent_loaded() {
  launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1
}

# Bootstrap the agent into the user's GUI domain. A plain `bootstrap gui/$uid` works
# from a console login but usually fails from an SSH shell (the caller isn't in the
# GUI bootstrap namespace) even when a desktop session is active — so fall back to
# `asuser`, which injects into this uid's running session. Both fail at the login
# window (no GUI session exists yet); the agent then loads on the next desktop login.
bootstrap_agent() {
  launchctl bootstrap "${DOMAIN}" "${PLIST}" 2>/dev/null && return 0
  launchctl asuser "${uid}" launchctl bootstrap "${DOMAIN}" "${PLIST}" 2>/dev/null
}

# Run the paseo CLI through mise so it works whether or not a shim was generated.
run_paseo() {
  if [[ -x "${MISE_BIN}" ]]; then
    "${MISE_BIN}" exec npm:@getpaseo/cli -- paseo "$@"
  elif command -v paseo >/dev/null 2>&1; then
    paseo "$@"
  else
    return 127
  fi
}

# Probe the CLI, capturing stderr into PASEO_DIAG so callers can surface the real
# reason on failure. "not resolvable" is ambiguous: it covers a genuinely missing
# tool AND an installed-but-broken one (e.g. an interrupted npm install leaves the
# bin unrunnable — mise then says `"paseo" couldn't exec process: No such file or
# directory`, which needs a reinstall, not `mise install`). Showing the raw error
# turns a multi-round guessing game into a one-look diagnosis.
PASEO_DIAG=""
paseo_available() {
  PASEO_DIAG="$(run_paseo --version 2>&1)"
}

# Deploy just the daemon plist. A bare `mise dotfiles apply` is all-or-nothing and
# aborts ("refusing to overwrite existing files") while $HOME still holds pre-mise
# real files (mid-migration), so the brand-new plist never lands. Targeting the one
# entry sidesteps those conflicts. No-op if mise or the [dotfiles] mapping is absent.
ensure_plist() {
  [[ -f "${PLIST}" ]] && return 0
  [[ -x "${MISE_BIN}" ]] || return 1
  log "Deploying the paseo LaunchAgent (targeted mise dotfiles apply)"
  "${MISE_BIN}" dotfiles apply "${PLIST}" -y >/dev/null 2>&1 || true
  [[ -f "${PLIST}" ]]
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
        run_paseo daemon status 2>/dev/null || warn "daemon status unavailable (still starting?)"
        log "Logs: ${HOME}/Library/Logs/paseo.daemon.log"
      else
        log "paseo daemon LaunchAgent is NOT loaded (load it with: just paseo)"
      fi
      return 0
      ;;
    pair)
      if ! paseo_available; then
        warn "paseo CLI not resolvable; run 'mise install' first"
        [[ -n "${PASEO_DIAG}" ]] && warn "mise exec said: ${PASEO_DIAG}"
        return 0
      fi
      run_paseo daemon pair
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
  if [[ ! -f "${PLIST}" ]] && ! ensure_plist; then
    warn "LaunchAgent not found at ${PLIST} and could not be deployed."
    warn "Deploy it with: mise dotfiles apply '~/Library/LaunchAgents/${LABEL}.plist'"
    return 0
  fi

  if ! paseo_available; then
    warn "paseo CLI not resolvable via mise; run 'mise install' (needs npm:@getpaseo/cli)"
    [[ -n "${PASEO_DIAG}" ]] && warn "mise exec said: ${PASEO_DIAG}"
    warn "if it names an installed tool, the install is broken: 'mise uninstall npm:@getpaseo/cli && mise install npm:@getpaseo/cli'"
    return 0
  fi

  if agent_loaded; then
    log "paseo daemon already loaded; restarting it"
    launchctl kickstart -k "${DOMAIN}/${LABEL}" 2>/dev/null || true
  else
    log "Loading the paseo daemon LaunchAgent"
    if ! bootstrap_agent; then
      warn "Could not bootstrap ${LABEL} into ${DOMAIN}."
      warn "This needs an active GUI login session for this user (not the login window)."
      warn "Over SSH: log the desktop user into m4pro's console, then re-run 'just paseo'."
      warn "Otherwise it loads automatically on the next desktop login (RunAtLoad)."
      return 0
    fi
    launchctl enable "${DOMAIN}/${LABEL}" 2>/dev/null || true
  fi

  log "paseo daemon is running (listening on :${PORT})."
  print_connect_hint
  log "First time: run 'just paseo --pair' for the QR/link, then approve in the phone app."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
