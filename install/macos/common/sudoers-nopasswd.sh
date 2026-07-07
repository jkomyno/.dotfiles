#!/usr/bin/env bash
# sudoers-nopasswd.sh — grant the current user passwordless sudo (opt-in).
#
# Typing the login password for every `sudo` during provisioning and remote
# administration gets old fast. This installs a validated /etc/sudoers.d drop-in
# so `sudo` stops prompting for this user.
#
# This is a deliberate security trade-off: anyone who gets a shell as this user
# then has root without a password. Enable it only where that is acceptable —
# e.g. a single-user dev box you also drive over SSH. It is therefore OPT-IN:
#
#   * As a staged setup step it is a no-op unless DOTFILES_ENABLE_NOPASSWD_SUDO=1.
#   * Run directly, or via `just nopasswd-sudo`, it proceeds.
#
# It needs `sudo` once to write the drop-in (validated with `visudo -c` before it
# is installed), and is idempotent afterwards.
#
# Modes:
#   (default)  Install the drop-in for the current user.
#   --check    Report whether passwordless sudo is already in effect. No changes.
#   --remove   Delete the drop-in this script installs.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

MODE="install"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | --plan) MODE="check" ;;
    --remove | --uninstall) MODE="remove" ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

TARGET_USER="$(id -un)"
# sudoers.d ignores any filename containing a dot, so sanitize the username.
SAFE_USER="${TARGET_USER//[^A-Za-z0-9_-]/_}"
DROPIN="/etc/sudoers.d/${SAFE_USER}-nopasswd"
RULE="${TARGET_USER} ALL=(ALL) NOPASSWD: ALL"

# True when sudo runs without prompting right now (drop-in already active, or the
# machine grants it some other way).
passwordless_active() {
  sudo -n true 2>/dev/null
}

case "${MODE}" in
  check)
    if passwordless_active; then
      log "passwordless sudo is active for ${TARGET_USER}"
    else
      log "passwordless sudo is NOT active for ${TARGET_USER} (enable with: just nopasswd-sudo)"
    fi
    if sudo -n test -f "${DROPIN}" 2>/dev/null; then
      log "drop-in present: ${DROPIN}"
    fi
    exit 0
    ;;
  remove)
    log "Removing ${DROPIN} (needs sudo once)"
    sudo rm -f "${DROPIN}"
    log "Removed. Re-run without --remove to restore."
    exit 0
    ;;
esac

# install
if [[ -z "${DOTFILES_ENABLE_NOPASSWD_SUDO:-}" && ! -t 0 ]]; then
  # Guard the staged-setup path: skip silently unless explicitly opted in, so a
  # normal provisioning run never flips a machine to passwordless sudo behind the
  # user's back.
  log "Skipping passwordless sudo (set DOTFILES_ENABLE_NOPASSWD_SUDO=1 to enable)"
  exit 0
fi

if passwordless_active && sudo -n test -f "${DROPIN}" 2>/dev/null; then
  log "Passwordless sudo already configured for ${TARGET_USER} (${DROPIN})"
  exit 0
fi

command -v visudo >/dev/null 2>&1 || die "visudo not found; cannot safely edit sudoers"

log "Configuring passwordless sudo for ${TARGET_USER} via ${DROPIN}"
log "(This needs your password once; after that sudo stops prompting.)"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
printf '# Managed by dotfiles: install/macos/common/sudoers-nopasswd.sh\n%s\n' "${RULE}" >"${tmp}"

# Validate the rule in isolation before it can affect the live sudoers.
if ! visudo -cf "${tmp}" >/dev/null; then
  die "generated sudoers rule failed validation; nothing installed"
fi

sudo install -m 0440 -o root -g wheel "${tmp}" "${DROPIN}"

# Confirm the live drop-in still parses (belt and suspenders).
if ! sudo visudo -cf "${DROPIN}" >/dev/null; then
  sudo rm -f "${DROPIN}"
  die "installed drop-in failed validation and was removed"
fi

log "Done. New sudo sessions for ${TARGET_USER} will not prompt for a password."
log "Undo with: bash install/macos/common/sudoers-nopasswd.sh --remove"
