#!/usr/bin/env bash
# screen-sharing.sh — enable macOS Screen Sharing for mac-to-mac VNC (opt-in).
#
# Turns on the built-in Remote Management agent (ARD) that also serves Screen
# Sharing, so another Mac connects over `vnc://<host>` and signs in with this
# machine's account password. Apple-to-Apple only: legacy (third-party) VNC is
# left disabled, because a plaintext VNC password is unencrypted and only needed
# by non-Apple clients.
#
# It uses Apple's `kickstart` rather than just loading com.apple.screensharing
# via launchctl: loading the service alone does NOT configure who may connect,
# which lands the machine in the "Screen Sharing is not permitted … disable and
# re-enable" state. kickstart activates the agent AND grants access (all local
# users, full privileges), and enable does a clean deactivate→activate cycle so a
# previously half-enabled machine recovers without touching System Settings.
#
# Enabling remote screen access widens this machine's attack surface, so like
# passwordless sudo it is OPT-IN and never runs during staged setup. Turn it on
# per-machine with `just screen-sharing`. It needs `sudo` and is idempotent.
#
# Modes:
#   (default)  Enable Screen Sharing (all local users, no legacy VNC password).
#   --check    Report whether Screen Sharing is currently enabled. No changes.
#   --remove   Disable Screen Sharing / Remote Management again.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly KICKSTART="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
readonly ARD_PREFS="/Library/Preferences/com.apple.RemoteManagement"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

MODE="enable"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | --plan) MODE="check" ;;
    --remove | --disable | --uninstall) MODE="remove" ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ "$(uname -s)" == "Darwin" ]] || die "Screen Sharing setup is macOS-only"
[[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"
[[ -x "${KICKSTART}" ]] || die "kickstart not found at ${KICKSTART}"

# True when the Remote Management agent is active and open to all local users.
screen_sharing_enabled() {
  sudo defaults read "${ARD_PREFS}" ARD_AllLocalUsers 2>/dev/null | grep -q '^1$'
}

# sudo needs cached credentials or a TTY to prompt on.
require_sudo() {
  if sudo -n -v 2>/dev/null; then
    return 0
  fi
  if [[ -r /dev/tty && -w /dev/tty ]]; then
    sudo -v
    return 0
  fi
  die "this needs sudo but no password prompt is available (run it from an interactive shell)"
}

# Print how to reach this Mac, preferring the stable Tailscale address.
print_connect_hint() {
  local addr=""
  if command -v tailscale >/dev/null 2>&1; then
    addr="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
  fi
  [[ -n "${addr}" ]] || addr="$(scutil --get LocalHostName 2>/dev/null).local"
  log "Connect from another Mac: open Finder > Go > Connect to Server > vnc://${addr}"
  log "then sign in with this Mac's account credentials."
}

case "${MODE}" in
  check)
    if screen_sharing_enabled; then
      log "Screen Sharing is ENABLED (Remote Management agent active, all local users)"
      print_connect_hint
    else
      log "Screen Sharing is NOT enabled (turn it on with: just screen-sharing)"
    fi
    exit 0
    ;;
  remove)
    require_sudo
    log "Disabling Screen Sharing / Remote Management"
    sudo "${KICKSTART}" -deactivate -configure -access -off
    log "Screen Sharing disabled."
    exit 0
    ;;
esac

# enable
require_sudo
log "Enabling native mac-to-mac Screen Sharing (all local users, no legacy VNC password)"

# Clean disable→enable cycle: this is the programmatic form of Apple's "disable
# and re-enable" recovery, so a machine stuck in the "not permitted" state comes
# back cleanly. -allowAccessFor -allUsers grants access (the piece launchctl
# alone omits); -setvnclegacy no keeps third-party VNC (plaintext password) off.
sudo "${KICKSTART}" -deactivate -configure -access -off
sudo "${KICKSTART}" -activate -configure \
  -allowAccessFor -allUsers \
  -privs -all \
  -clientopts -setvnclegacy -vnclegacy no \
  -restart -agent

if screen_sharing_enabled; then
  log "Screen Sharing enabled."
  print_connect_hint
else
  warn "Could not confirm Screen Sharing is active; check System Settings > General > Sharing."
fi

log "Undo with: just screen-sharing --remove"
