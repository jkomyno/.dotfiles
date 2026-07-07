#!/usr/bin/env bash
# tailscale.sh — install the headless tailscaled system daemon and join the tailnet.
#
# The tailscale CLI/daemon comes from the Homebrew `tailscale` formula (declared
# in install/macos/common/nanobrew-formulae.Brewfile) because it ships a root
# LaunchDaemon (`tailscaled`), not just a versioned CLI — the same reason fish and
# ffmpeg live there rather than in mise. This script wires that daemon up so a Mac
# driven purely over SSH can reach its tailnet without ever opening the GUI app:
#
#   1. `tailscaled install-system-daemon` registers /Library/LaunchDaemons and
#      starts tailscaled as root (needs sudo once; idempotent afterwards).
#   2. `tailscale up` joins the tailnet. Authentication is interactive by design
#      (browser SSO), mirroring how gh/codex/claude auth is a guided manual step:
#        * With TAILSCALE_AUTHKEY set, it joins non-interactively.
#        * Otherwise it prints the login URL to open, then exits cleanly.
#
# Guarded to a no-op on non-Apple-Silicon-macOS so a future Linux profile applies
# cleanly, and skippable via DOTFILES_SKIP_TAILSCALE=1. Wired into staged setup as
# an optional (network-dependent) step; re-run any time with `just tailscale`.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly NANOBREW_PREFIX="${NANOBREW_PREFIX:-/opt/nanobrew/prefix}"
readonly TAILSCALED_PLIST="/Library/LaunchDaemons/com.tailscale.tailscaled.plist"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }

# Resolve a tailscale binary from PATH first, then the nanobrew prefix, since a
# freshly provisioned shell may not have the prefix on PATH yet.
resolve_bin() {
  local name="$1"
  if command -v "${name}" >/dev/null 2>&1; then
    command -v "${name}"
    return 0
  fi
  if [[ -x "${NANOBREW_PREFIX}/bin/${name}" ]]; then
    printf '%s\n' "${NANOBREW_PREFIX}/bin/${name}"
    return 0
  fi
  return 1
}

# sudo needs cached credentials or a TTY to prompt on. Skip privileged steps in a
# headless run (e.g. CI) instead of hanging or aborting the whole staged setup.
sudo_available() {
  sudo -n -v 2>/dev/null && return 0
  [[ -r /dev/tty && -w /dev/tty ]]
}

install_system_daemon() {
  local tailscaled="$1"

  if [[ -f "${TAILSCALED_PLIST}" ]]; then
    log "tailscaled system daemon already installed (${TAILSCALED_PLIST})"
    return 0
  fi

  if ! sudo_available; then
    warn "Skipping tailscaled install-system-daemon: sudo needs a password but no TTY is available"
    return 1
  fi

  log "Installing the tailscaled system daemon (needs sudo once)"
  sudo "${tailscaled}" install-system-daemon
}

join_tailnet() {
  local tailscale="$1"

  # `tailscale status` exits non-zero when logged out; treat a clean exit as
  # already connected so re-runs are no-ops.
  if "${tailscale}" status >/dev/null 2>&1; then
    log "Already connected to a tailnet ($(${tailscale} ip -4 2>/dev/null | head -n1))"
    return 0
  fi

  if [[ -n "${TAILSCALE_AUTHKEY:-}" ]]; then
    log "Joining the tailnet with TAILSCALE_AUTHKEY"
    sudo "${tailscale}" up --authkey="${TAILSCALE_AUTHKEY}"
    log "Connected as $(${tailscale} ip -4 2>/dev/null | head -n1)"
    return 0
  fi

  # No auth key: authentication is interactive (browser SSO), so guide the user
  # rather than block staged setup. `tailscale up` prints a login URL and waits;
  # run it yourself when convenient.
  log "Tailscale is installed but not logged in yet."
  log "Finish joining your tailnet with:"
  log "    tailscale up          # opens a browser login URL"
  log "    tailscale up --ssh    # also enable Tailscale SSH into this Mac"
}

main() {
  if [[ -n "${DOTFILES_SKIP_TAILSCALE:-}" ]]; then
    log "Skipping tailscale setup (DOTFILES_SKIP_TAILSCALE is set)"
    return 0
  fi

  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || return 0

  local tailscale tailscaled
  if ! tailscaled="$(resolve_bin tailscaled)" || ! tailscale="$(resolve_bin tailscale)"; then
    warn "tailscale is not installed yet; run the nanobrew formulae step first (brew \"tailscale\")"
    return 0
  fi

  install_system_daemon "${tailscaled}" || return 0
  join_tailnet "${tailscale}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
