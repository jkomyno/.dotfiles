#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/jkomyno/dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-${BRANCH_NAME:-main}}"
readonly CHEZMOI_BIN_DIR="${CHEZMOI_BIN_DIR:-${HOME}/.local/bin}"
readonly SUDO_KEYCHAIN_SERVICE="dotfiles-bootstrap"

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
  run_chezmoi

  log "Done"
}

main "$@"
