#!/usr/bin/env bash
# agentmemory.sh — manage the agentmemory user service so shared memory is
# always available through launchd or a systemd user service.
#
# agentmemory (https://github.com/rohitg00/agentmemory) is the cross-session memory
# server for Claude Code, Codex, and pi. The CLI is a mise tool
# (npm:@agentmemory/agentmemory). macOS uses a tracked LaunchAgent and Linux uses
# a tracked systemd user service. This script manages the native user service.
#
# It serves the memory REST API on http://localhost:3111 and a viewer on :3113,
# localhost-only — nothing is exposed on the network.
#
# agentmemory is resolved through `mise exec npm:@agentmemory/agentmemory` rather
# than a shim, because a shim is not always generated (activate-mode machines),
# whereas `mise exec` always resolves an installed mise tool.
#
# Skippable via DOTFILES_SKIP_AGENTMEMORY=1 and wired into staged setup as an
# optional step; manage it any time with `just agentmemory`.
#
# Modes:
#   (default)  Load (and (re)start) the agentmemory daemon user service.
#   --status   Report the agent state and server health. No changes.
#   --remove   Disable the user service.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly LABEL="com.agentmemory.daemon"
readonly PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
readonly SYSTEMD_UNIT_NAME="agentmemory.service"
readonly SYSTEMD_UNIT="${HOME}/.config/systemd/user/${SYSTEMD_UNIT_NAME}"
readonly PORT="3111"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_ROOT="${DOTFILES:-$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)}"

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

# Run the agentmemory CLI through mise so it works whether or not a shim was generated.
run_agentmemory() {
  if [[ -x "${MISE_BIN}" ]]; then
    "${MISE_BIN}" exec npm:@agentmemory/agentmemory -- agentmemory "$@"
  elif command -v agentmemory >/dev/null 2>&1; then
    agentmemory "$@"
  else
    return 127
  fi
}

# Probe the CLI, capturing stderr into AM_DIAG so callers can surface the real
# reason on failure. "not resolvable" covers both a missing tool and an installed-
# but-broken one (an interrupted npm install leaves the bin unrunnable); showing the
# raw error turns a guessing game into a one-look diagnosis.
AM_DIAG=""
agentmemory_available() {
  AM_DIAG="$(run_agentmemory --version 2>&1)"
}

server_healthy() {
  curl -sS -m 3 "http://localhost:${PORT}/agentmemory/health" >/dev/null 2>&1
}

# Deploy just the daemon plist. A bare `mise bootstrap dotfiles apply` is all-or-nothing and
# aborts ("refusing to overwrite existing files") while $HOME still holds pre-mise
# real files (mid-migration), so the brand-new plist never lands. Targeting the one
# entry sidesteps those conflicts. No-op if mise or the [dotfiles] mapping is absent.
ensure_plist() {
  [[ -f "${PLIST}" ]] && return 0
  [[ -x "${MISE_BIN}" ]] || return 1
  log "Deploying the agentmemory LaunchAgent"
  MISE_AUTO_ENV=true MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap dotfiles apply "${PLIST}" --yes >/dev/null 2>&1 || true
  [[ -f "${PLIST}" ]]
}

systemd_user_available() {
  command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1
}

ensure_lingering() {
  local user
  user="$(id -un)"
  if ! command -v loginctl >/dev/null 2>&1; then
    warn "loginctl is unavailable; ${SYSTEMD_UNIT_NAME} may stop after logout"
    return 0
  fi
  if [[ "$(loginctl show-user "${user}" -p Linger --value 2>/dev/null || true)" == "yes" ]]; then
    return 0
  fi
  if loginctl enable-linger "${user}" >/dev/null 2>&1 ||
    { command -v sudo >/dev/null 2>&1 && sudo -n loginctl enable-linger "${user}" >/dev/null 2>&1; }; then
    log "Enabled systemd lingering for ${user}"
    return 0
  fi
  warn "systemd lingering is disabled; run 'sudo loginctl enable-linger ${user}' so agentmemory survives logout"
}

ensure_systemd_unit() {
  [[ -e "${SYSTEMD_UNIT}" || -L "${SYSTEMD_UNIT}" ]] && return 0
  [[ -x "${MISE_BIN}" ]] || return 1
  log "Deploying the agentmemory systemd user unit"
  MISE_AUTO_ENV=true MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap dotfiles apply "${SYSTEMD_UNIT}" --yes >/dev/null 2>&1 || true
  [[ -e "${SYSTEMD_UNIT}" || -L "${SYSTEMD_UNIT}" ]]
}

linux_main() {
  if ! systemd_user_available; then
    warn "systemd user manager is unavailable; dotfiles and tools remain installed, but agentmemory was not started"
    warn "Use a systemd login session, then run 'just agentmemory' again"
    return 0
  fi

  case "${MODE}" in
    status)
      if systemctl --user is-active --quiet "${SYSTEMD_UNIT_NAME}"; then
        log "agentmemory systemd user service is active"
      else
        log "agentmemory systemd user service is NOT active (start it with: just agentmemory)"
      fi
      if server_healthy; then
        log "Server healthy at http://localhost:${PORT} (viewer: http://localhost:3113)"
      else
        warn "Server not responding on :${PORT} yet (still starting?)"
      fi
      log "Logs: journalctl --user -u ${SYSTEMD_UNIT_NAME}"
      return 0
      ;;
    remove)
      log "Disabling the agentmemory systemd user service"
      systemctl --user disable --now "${SYSTEMD_UNIT_NAME}" >/dev/null 2>&1 || true
      return 0
      ;;
  esac

  if [[ ! -e "${SYSTEMD_UNIT}" && ! -L "${SYSTEMD_UNIT}" ]] && ! ensure_systemd_unit; then
    warn "systemd unit not found at ${SYSTEMD_UNIT} and could not be deployed"
    return 0
  fi
  if ! agentmemory_available; then
    warn "agentmemory CLI not resolvable via mise; run 'mise install' (needs npm:@agentmemory/agentmemory)"
    [[ -n "${AM_DIAG}" ]] && warn "mise exec said: ${AM_DIAG}"
    return 0
  fi

  mkdir -p "${HOME}/.agentmemory"
  ensure_lingering
  systemctl --user daemon-reload
  systemctl --user enable --now "${SYSTEMD_UNIT_NAME}"
  systemctl --user restart "${SYSTEMD_UNIT_NAME}"
  log "agentmemory systemd user service is running (REST on http://localhost:${PORT}, viewer :3113)"
}

main() {
  if [[ -n "${DOTFILES_SKIP_AGENTMEMORY:-}" ]]; then
    log "Skipping agentmemory daemon setup (DOTFILES_SKIP_AGENTMEMORY is set)"
    return 0
  fi

  if [[ "$(uname -s)" == "Linux" ]]; then
    linux_main
    return 0
  fi
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  case "${MODE}" in
    status)
      if agent_loaded; then
        log "agentmemory daemon LaunchAgent is loaded (${LABEL})"
      else
        log "agentmemory daemon LaunchAgent is NOT loaded (load it with: just agentmemory)"
      fi
      if server_healthy; then
        log "Server healthy at http://localhost:${PORT} (viewer: http://localhost:3113)"
      else
        warn "Server not responding on :${PORT} yet (still starting?)"
      fi
      log "Logs: ${HOME}/Library/Logs/agentmemory.daemon.log"
      return 0
      ;;
    remove)
      log "Unloading the agentmemory daemon LaunchAgent"
      launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
      log "Unloaded. Re-run without --remove to restore."
      return 0
      ;;
  esac

  # load
  if [[ ! -f "${PLIST}" ]] && ! ensure_plist; then
    warn "LaunchAgent not found at ${PLIST} and could not be deployed."
    warn "Deploy it with: mise bootstrap dotfiles apply '~/Library/LaunchAgents/${LABEL}.plist'"
    return 0
  fi

  if ! agentmemory_available; then
    warn "agentmemory CLI not resolvable via mise; run 'mise install' (needs npm:@agentmemory/agentmemory)"
    [[ -n "${AM_DIAG}" ]] && warn "mise exec said: ${AM_DIAG}"
    warn "if it names an installed tool, the install is broken: 'mise uninstall npm:@agentmemory/agentmemory && mise install npm:@agentmemory/agentmemory'"
    return 0
  fi

  if agent_loaded; then
    log "agentmemory daemon already loaded; restarting it"
    launchctl kickstart -k "${DOMAIN}/${LABEL}" 2>/dev/null || true
  else
    log "Loading the agentmemory daemon LaunchAgent"
    if ! bootstrap_agent; then
      warn "Could not bootstrap ${LABEL} into ${DOMAIN}."
      warn "This needs an active GUI login session for this user (not the login window)."
      warn "Over SSH: log the desktop user into the console, then re-run 'just agentmemory'."
      warn "Otherwise it loads automatically on the next desktop login (RunAtLoad)."
      return 0
    fi
    launchctl enable "${DOMAIN}/${LABEL}" 2>/dev/null || true
  fi

  log "agentmemory daemon is running (REST on http://localhost:${PORT}, viewer :3113)."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
