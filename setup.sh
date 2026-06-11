#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/jkomyno/dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-${BRANCH_NAME:-main}}"
readonly CHEZMOI_BIN_DIR="${CHEZMOI_BIN_DIR:-${HOME}/.local/bin}"
readonly SUDO_KEYCHAIN_SERVICE="dotfiles-bootstrap"
readonly DEFAULT_DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro"

DOTFILES_LOGO="$(
  cat <<'LOGO'
                          /$$                                      /$$
                         | $$                                     | $$
     /$$$$$$$  /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$      /$$$$$$$| $$$$$$$
    /$$_____/ /$$__  $$|_  $$_/  | $$  | $$ /$$__  $$    /$$_____/| $$__  $$
   |  $$$$$$ | $$$$$$$$  | $$    | $$  | $$| $$  \ $$   |  $$$$$$ | $$  \ $$
    \____  $$| $$_____/  | $$ /$$| $$  | $$| $$  | $$    \____  $$| $$  | $$
    /$$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/| $$$$$$$//$$ /$$$$$$$/| $$  | $$
   |_______/  \_______/   \___/   \______/ | $$____/|__/|_______/ |__/  |__/
                                           | $$
                                           | $$
                                           |__/

             *** This is setup script for my dotfiles setup ***
LOGO
  printf '                     %s\n' "${DOTFILES_REPO_URL}"
)"
readonly DOTFILES_LOGO

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

is_non_interactive() {
  [[ "${CI:-}" == "true" || ! -t 0 ]]
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

cleanup_sudo_macos() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "${SUDO_KEEPALIVE_PID}" >/dev/null 2>&1 || true
  fi

  if [[ -n "${SUDO_ASKPASS:-}" ]]; then
    rm -f "${SUDO_ASKPASS}"
  fi

  /usr/bin/security delete-generic-password \
    -s "${SUDO_KEYCHAIN_SERVICE}" \
    -a "${USER}" \
    >/dev/null 2>&1 || true
}

keepalive_sudo_macos() {
  if [[ "${CI:-}" == "true" ]]; then
    return
  fi

  if ! has_tty; then
    log "Skipping sudo keepalive because /dev/tty is unavailable"
    return
  fi

  log "Preparing sudo access"
  local password
  IFS= read -r -s -p "Password: " password </dev/tty
  printf '\n' >/dev/tty

  /usr/bin/security add-generic-password \
    -U \
    -s "${SUDO_KEYCHAIN_SERVICE}" \
    -a "${USER}" \
    -w "${password}" \
    >/dev/null

  SUDO_ASKPASS="$(mktemp)"
  export SUDO_ASKPASS
  cat >"${SUDO_ASKPASS}" <<ASKPASS
#!/bin/sh
/usr/bin/security find-generic-password -s "${SUDO_KEYCHAIN_SERVICE}" -a "${USER}" -w
ASKPASS
  chmod 700 "${SUDO_ASKPASS}"

  trap cleanup_sudo_macos EXIT

  if ! /usr/bin/sudo -A -k -v; then
    cleanup_sudo_macos
    die "incorrect sudo password"
  fi

  while true; do
    /usr/bin/sudo -A -v
    sleep 60
    kill -0 "$$" >/dev/null 2>&1 || exit
  done >/dev/null 2>&1 &
  SUDO_KEEPALIVE_PID="$!"
}

keepalive_sudo() {
  case "$(uname -s)" in
    Darwin)
      keepalive_sudo_macos
      ;;
    Linux)
      log "Skipping sudo keepalive on Linux for now"
      ;;
  esac
}

sanitize_local_hostname() {
  local name="$1"

  printf '%s' "${name}" |
    tr '[:upper:]' '[:lower:]' |
    tr -d "'" |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

sanitize_netbios_name() {
  local name="$1"

  printf '%s' "${name}" |
    tr '[:lower:]' '[:upper:]' |
    tr -cd '[:alnum:]-' |
    cut -c 1-15
}

current_scutil_name() {
  local key="$1"

  scutil --get "${key}" 2>/dev/null || true
}

set_scutil_name() {
  local key="$1"
  local value="$2"

  [[ -n "${value}" ]] || return 0

  if [[ "$(current_scutil_name "${key}")" == "${value}" ]]; then
    log "${key} already set to ${value}"
    return 0
  fi

  log "Setting ${key} to ${value}"
  sudo -A scutil --set "${key}" "${value}"
}

configure_macos_computer_name() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  # Machine identity is setup-time state. Keep it out of repeatable chezmoi
  # defaults so a later apply cannot unexpectedly rename a Mac.
  if [[ "${CI:-}" == "true" ]]; then
    log "Skipping computer name setup in CI"
    return 0
  fi

  if [[ -z "${SUDO_ASKPASS:-}" ]] && ! has_tty; then
    log "Skipping computer name setup because sudo is unavailable without a TTY"
    return 0
  fi

  if [[ -n "${DOTFILES_SKIP_COMPUTER_NAME:-}" ]]; then
    log "Skipping computer name setup (DOTFILES_SKIP_COMPUTER_NAME is set)"
    return 0
  fi

  local computer_name
  local local_hostname
  local netbios_name

  computer_name="${DOTFILES_COMPUTER_NAME:-${DEFAULT_DOTFILES_COMPUTER_NAME}}"
  local_hostname="${DOTFILES_LOCAL_HOSTNAME:-$(sanitize_local_hostname "${computer_name}")}"
  netbios_name="${DOTFILES_NETBIOS_NAME:-$(sanitize_netbios_name "${local_hostname}")}"

  [[ -n "${computer_name}" ]] || die "DOTFILES_COMPUTER_NAME cannot be empty"
  [[ -n "${local_hostname}" ]] || die "DOTFILES_LOCAL_HOSTNAME cannot be empty"
  [[ -n "${netbios_name}" ]] || die "DOTFILES_NETBIOS_NAME cannot be empty"

  set_scutil_name ComputerName "${computer_name}"
  set_scutil_name LocalHostName "${local_hostname}"

  if [[ -n "${DOTFILES_HOST_NAME:-}" ]]; then
    set_scutil_name HostName "${DOTFILES_HOST_NAME}"
  fi

  local current_netbios_name
  current_netbios_name="$(defaults read /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName 2>/dev/null || true)"
  if [[ "${current_netbios_name}" == "${netbios_name}" ]]; then
    log "NetBIOSName already set to ${netbios_name}"
    return 0
  fi

  log "Setting NetBIOSName to ${netbios_name}"
  sudo -A defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${netbios_name}"
}

ensure_chezmoi() {
  mkdir -p "${CHEZMOI_BIN_DIR}"
  export PATH="${CHEZMOI_BIN_DIR}:${PATH}"

  if command -v chezmoi >/dev/null 2>&1; then
    command -v chezmoi
    return
  fi

  log "Installing chezmoi"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "${CHEZMOI_BIN_DIR}" >&2

  [[ -x "${CHEZMOI_BIN_DIR}/chezmoi" ]] || die "chezmoi install did not create ${CHEZMOI_BIN_DIR}/chezmoi"
  printf '%s\n' "${CHEZMOI_BIN_DIR}/chezmoi"
}

run_chezmoi() {
  local chezmoi_cmd
  chezmoi_cmd="$(ensure_chezmoi)"

  local -a tty_args=()
  if is_non_interactive; then
    tty_args=("--no-tty")
  fi

  log "Initializing dotfiles from ${DOTFILES_REPO_URL}#${DOTFILES_BRANCH}"
  "${chezmoi_cmd}" init "${DOTFILES_REPO_URL}" \
    --branch "${DOTFILES_BRANCH}" \
    --force \
    --use-builtin-git true \
    "${tty_args[@]}"

  log "Applying dotfiles"
  "${chezmoi_cmd}" apply "${tty_args[@]}"
}

main() {
  printf '%s\n' "${DOTFILES_LOGO}"
  require_command curl

  keepalive_sudo
  configure_macos_computer_name
  run_chezmoi

  log "Done"
}

main "$@"
