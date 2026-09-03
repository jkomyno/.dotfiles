#!/usr/bin/env bash
# rust-cache.sh — install and manage periodic Rust build-cache maintenance.
#
# macOS uses a LaunchAgent; Linux uses a systemd user timer. Both trigger daily
# so missed runs recover after sleep or downtime. The maintenance script's
# persistent timestamp permits an actual cleanup only once every 14 days.
#
# Modes:
#   (default)  Install and enable the platform scheduler.
#   --status   Report whether the scheduler is loaded.
#   --dry-run  Preview currently eligible target directories.
#   --run      Run cleanup now, outside the 14-day cadence.
#   --remove   Disable the scheduler.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly LABEL="com.jkomyno.rust-cache-maintenance"
readonly PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
readonly SYSTEMD_SERVICE_NAME="rust-cache-maintenance.service"
readonly SYSTEMD_TIMER_NAME="rust-cache-maintenance.timer"
readonly SYSTEMD_SERVICE="${HOME}/.config/systemd/user/${SYSTEMD_SERVICE_NAME}"
readonly SYSTEMD_TIMER="${HOME}/.config/systemd/user/${SYSTEMD_TIMER_NAME}"
readonly CLEANER="${HOME}/.local/bin/rust-cache-maintenance"
readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
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
    --dry-run) MODE="preview" ;;
    --run) MODE="run" ;;
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

deploy_dotfile() {
  local destination="$1"
  [[ -e "${destination}" || -L "${destination}" ]] && return 0
  [[ -x "${MISE_BIN}" ]] || return 1
  MISE_AUTO_ENV=true MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap dotfiles apply "${destination}" --yes >/dev/null 2>&1 || true
  [[ -e "${destination}" || -L "${destination}" ]]
}

ensure_cleaner() {
  [[ -x "${CLEANER}" ]] || deploy_dotfile "${CLEANER}"
}

cleaner_available() {
  ensure_cleaner || return 1
  "${CLEANER}" --check
}

systemd_user_available() {
  command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1
}

ensure_lingering() {
  local user
  user="$(id -un)"
  if ! command -v loginctl >/dev/null 2>&1; then
    warn "loginctl is unavailable; ${SYSTEMD_TIMER_NAME} may stop after logout"
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
  warn "systemd lingering is disabled; run 'sudo loginctl enable-linger ${user}'"
}

linux_main() {
  if ! systemd_user_available; then
    warn "systemd user manager is unavailable; Rust cache configuration remains installed"
    warn "Use a systemd login session, then run 'just rust-cache' again"
    return 0
  fi

  case "${MODE}" in
    status)
      if systemctl --user is-active --quiet "${SYSTEMD_TIMER_NAME}"; then
        log "Rust cache maintenance timer is active"
      else
        log "Rust cache maintenance timer is NOT active (enable it with: just rust-cache)"
      fi
      log "Logs: journalctl --user -u ${SYSTEMD_SERVICE_NAME}"
      return 0
      ;;
    remove)
      systemctl --user disable --now "${SYSTEMD_TIMER_NAME}" >/dev/null 2>&1 || true
      log "Rust cache maintenance timer disabled"
      return 0
      ;;
  esac

  deploy_dotfile "${SYSTEMD_SERVICE}" || {
    warn "Could not deploy ${SYSTEMD_SERVICE}"
    return 0
  }
  deploy_dotfile "${SYSTEMD_TIMER}" || {
    warn "Could not deploy ${SYSTEMD_TIMER}"
    return 0
  }
  cleaner_available || {
    warn "cargo-clean-all is unavailable; run 'mise install cargo:cargo-clean-all'"
    return 0
  }

  ensure_lingering
  systemctl --user daemon-reload
  systemctl --user enable --now "${SYSTEMD_TIMER_NAME}"
  log "Rust cache maintenance timer enabled; cleanup is admitted every 14 days"
}

macos_main() {
  case "${MODE}" in
    status)
      if launchctl print "${DOMAIN}/${LABEL}" >/dev/null 2>&1; then
        log "Rust cache maintenance LaunchAgent is loaded"
      else
        log "Rust cache maintenance LaunchAgent is NOT loaded (load it with: just rust-cache)"
      fi
      log "Logs: ${HOME}/Library/Logs/rust-cache-maintenance.log"
      return 0
      ;;
    remove)
      launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
      log "Rust cache maintenance LaunchAgent unloaded"
      return 0
      ;;
  esac

  deploy_dotfile "${PLIST}" || {
    warn "Could not deploy ${PLIST}"
    return 0
  }
  cleaner_available || {
    warn "cargo-clean-all is unavailable; run 'mise install cargo:cargo-clean-all'"
    return 0
  }

  launchctl bootout "${DOMAIN}/${LABEL}" 2>/dev/null || true
  if ! launchctl bootstrap "${DOMAIN}" "${PLIST}" 2>/dev/null &&
    ! launchctl asuser "${uid}" launchctl bootstrap "${DOMAIN}" "${PLIST}" 2>/dev/null; then
    warn "Could not load ${LABEL}; an active GUI login session is required"
    return 0
  fi
  launchctl enable "${DOMAIN}/${LABEL}" 2>/dev/null || true
  log "Rust cache maintenance LaunchAgent loaded; cleanup is admitted every 14 days"
}

main() {
  case "${MODE}" in
    preview | run)
      ensure_cleaner || die "maintenance command is unavailable"
      ;;
  esac

  case "${MODE}" in
    preview) exec "${CLEANER}" --dry-run ;;
    run) exec "${CLEANER}" --apply ;;
  esac

  case "$(uname -s)" in
    Linux) linux_main ;;
    Darwin) macos_main ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
