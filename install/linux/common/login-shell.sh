#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_ROOT="${DOTFILES:-$(cd -- "${SCRIPT_DIR}/../../.." && pwd -P)}"
readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"

log() { printf '==> %s\n' "$*" >&2; }
die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

main() {
  local dry_run="false"
  local arg
  local target_user
  local current_shell

  [[ "$(uname -s)" == "Linux" ]] || return 0
  if [[ "${DOTFILES_SKIP_LOGIN_SHELL:-}" == "1" ]]; then
    log "Skipping login shell change (DOTFILES_SKIP_LOGIN_SHELL=1)"
    return 0
  fi

  [[ -x /usr/bin/zsh ]] || die "/usr/bin/zsh is missing; run the Linux package step first"
  [[ -x "${MISE_BIN}" ]] || die "mise is missing: ${MISE_BIN}"

  for arg in "$@"; do
    [[ "${arg}" == "--dry-run" || "${arg}" == "-n" ]] && dry_run="true"
  done

  target_user="$(id -un)"
  current_shell="$(getent passwd "${target_user}" | cut -d: -f7)"
  if [[ "${dry_run}" == "false" && "${current_shell}" == "/usr/bin/zsh" ]]; then
    log "/usr/bin/zsh is already the login shell for ${target_user}"
    return 0
  fi

  # mise's user bootstrap deliberately uses chsh. On passwordless-sudo hosts,
  # apply the same declared value through privileged chsh so unattended setup
  # does not stop at PAM's password prompt. Keep the mise dry-run as validation
  # that the platform profile still declares the expected operation.
  if [[ "${dry_run}" == "false" ]] && command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    MISE_AUTO_ENV=true \
      MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
      "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap user apply --yes --dry-run >/dev/null
    sudo -n chsh -s /usr/bin/zsh "${target_user}"
    log "Set /usr/bin/zsh as the login shell for ${target_user}"
    return 0
  fi

  MISE_AUTO_ENV=true \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${MISE_BIN}" -C "${DOTFILES_ROOT}" bootstrap user apply --yes "$@"
}

main "$@"
