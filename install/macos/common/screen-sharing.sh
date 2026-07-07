#!/usr/bin/env bash
# screen-sharing.sh — enable macOS's native Screen Sharing for mac-to-mac VNC (opt-in).
#
# Turns on the built-in `com.apple.screensharing` LaunchDaemon (System Settings >
# General > Sharing > Screen Sharing) so another Mac can connect over Screen
# Sharing / `vnc://` and authenticate with this machine's account password. It is
# deliberately Apple-to-Apple only: no legacy VNC password is set, because a
# plaintext VNC password is unencrypted and only needed by third-party clients.
#
# Enabling remote screen access widens this machine's attack surface, so like
# passwordless sudo it is OPT-IN and never runs during staged setup. Turn it on
# per-machine with `just screen-sharing` (or run this script directly). It needs
# `sudo` to load the system daemon and is idempotent afterwards.
#
# Modes:
#   (default)  Enable Screen Sharing.
#   --check    Report whether Screen Sharing is currently enabled. No changes.
#   --remove   Disable Screen Sharing again.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly SERVICE="com.apple.screensharing"
readonly PLIST="/System/Library/LaunchDaemons/${SERVICE}.plist"

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

# True when the Screen Sharing daemon is registered in the system launchd domain.
screen_sharing_enabled() {
  sudo launchctl print "system/${SERVICE}" >/dev/null 2>&1
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
      log "Screen Sharing is ENABLED"
      print_connect_hint
    else
      log "Screen Sharing is NOT enabled (turn it on with: just screen-sharing)"
    fi
    exit 0
    ;;
  remove)
    require_sudo
    log "Disabling Screen Sharing"
    sudo launchctl bootout "system/${SERVICE}" 2>/dev/null || true
    sudo launchctl disable "system/${SERVICE}" 2>/dev/null || true
    log "Screen Sharing disabled."
    exit 0
    ;;
esac

# enable
if screen_sharing_enabled; then
  log "Screen Sharing is already enabled"
  print_connect_hint
  exit 0
fi

require_sudo
log "Enabling native mac-to-mac Screen Sharing"

# `enable` clears any prior disable override and persists across reboots;
# `bootstrap` loads the daemon now. On macOS releases without `bootstrap`, fall
# back to the legacy `load -w`. A daemon that is already loaded makes bootstrap
# exit non-zero, which is fine here.
sudo launchctl enable "system/${SERVICE}" 2>/dev/null || true
if ! sudo launchctl bootstrap system "${PLIST}" 2>/dev/null; then
  sudo launchctl load -w "${PLIST}" 2>/dev/null || true
fi

if screen_sharing_enabled; then
  log "Screen Sharing enabled."
  print_connect_hint
else
  warn "Could not confirm Screen Sharing is active."
  warn "On recent macOS you may need to approve it once in System Settings > General > Sharing."
fi

log "Undo with: just screen-sharing --remove"
