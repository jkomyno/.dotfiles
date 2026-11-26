#!/usr/bin/env bash

if [[ -n "${DOTFILES_LIB_LOADED:-}" ]]; then
  return 0
fi
readonly DOTFILES_LIB_LOADED=1

set -Eeuo pipefail

if ! locale >/dev/null 2>&1; then
  export LC_ALL=C
  export LANG=C
fi

dotfiles_repo_root() {
  local script_dir
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
  cd -- "${script_dir}/../.." && pwd -P
}

readonly DOTFILES_ROOT="${DOTFILES:-$(dotfiles_repo_root)}"
readonly DOTFILES_MISE_DIR="${DOTFILES_ROOT}/target/home/.config/mise"
readonly DOTFILES_MISE_CONFIG="${DOTFILES_MISE_DIR}/config.toml"
readonly DOTFILES_MISE_PLATFORMS="${DOTFILES_MISE_PLATFORMS:-linux-x64,linux-arm64,macos-arm64}"
readonly DOTFILES_MISE_LINUX_PLATFORMS="${DOTFILES_MISE_LINUX_PLATFORMS:-linux-x64,linux-arm64}"
readonly DOTFILES_MISE_MINIMUM_RELEASE_AGE="${DOTFILES_MISE_MINIMUM_RELEASE_AGE:-0s}"

source "${DOTFILES_MISE_DIR}/dotfiles-profile.sh"

log() {
  printf '==> %s\n' "$*" >&2
}

info() {
  printf 'info: %s\n' "$*" >&2
}

warn() {
  printf 'warn: %s\n' "$*" >&2
}

error() {
  printf 'error: %s\n' "$*" >&2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

os_name() {
  uname -s
}

is_macos() {
  [[ "$(os_name)" == "Darwin" ]]
}

is_linux() {
  [[ "$(os_name)" == "Linux" ]]
}

mise_bin() {
  if [[ -n "${MISE_INSTALL_PATH:-}" && -x "${MISE_INSTALL_PATH}" ]]; then
    printf '%s\n' "${MISE_INSTALL_PATH}"
  elif have mise; then
    command -v mise
  elif [[ -x "${HOME}/.local/bin/mise" ]]; then
    printf '%s\n' "${HOME}/.local/bin/mise"
  else
    return 1
  fi
}

run_source_mise() {
  local mise_cmd
  mise_cmd="$(mise_bin)" || return 127

  env \
    MISE_AUTO_ENV="${MISE_AUTO_ENV:-true}" \
    MISE_CEILING_PATHS="${DOTFILES_ROOT}" \
    MISE_GLOBAL_CONFIG_FILE="${DOTFILES_MISE_CONFIG}" \
    MISE_DEFAULT_CONFIG_FILENAME="config.toml" \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_MISE_DIR}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    MISE_IGNORED_CONFIG_PATHS="${DOTFILES_ROOT}/mise.toml:${DOTFILES_ROOT}/mise.linux.toml:${DOTFILES_ROOT}/mise.macos.toml${MISE_IGNORED_CONFIG_PATHS:+:${MISE_IGNORED_CONFIG_PATHS}}" \
    NPM_CONFIG_UPDATE_NOTIFIER="false" \
    "${mise_cmd}" -C "${DOTFILES_MISE_DIR}" "$@"
}

run_source_mise_base() {
  MISE_AUTO_ENV=false run_source_mise "$@"
}

require_file() {
  local path="$1"
  [[ -e "${path}" ]] || {
    error "missing required file: ${path#"${DOTFILES_ROOT}"/}"
    return 1
  }
}

profile_identity() { [[ "${DOTFILES_PROFILE}" == full || "${DOTFILES_MIGRATE_IDENTITY:-0}" == 1 ]]; }

profile_paseo() {
  [[ "${DOTFILES_PROFILE}" == full || "${DOTFILES_MIGRATE_PASEO:-0}" == 1 ]] && return 0
  local unit="${HOME}/.config/systemd/user/paseo.service"
  if is_macos; then unit="${HOME}/Library/LaunchAgents/sh.paseo.daemon.plist"; fi
  # Existing units and running services are migrated separately on work machines.
  if is_linux && [[ -L "${unit}" && "${unit}" -ef "${DOTFILES_ROOT}/target/home/.config/systemd/user/paseo-mise.service" ]]; then return 0; fi
  [[ ! -e "${unit}" && ! -L "${unit}" ]] || return 1
  if is_linux && command -v systemctl >/dev/null && systemctl --user is-active --quiet paseo.service 2>/dev/null; then return 1; fi
  return 0
}

# Install each selected Pi package before Paseo starts concurrent provider probes.
sync_selected_pi_packages() {
  local packages package failed=0
  packages="$(bash "${DOTFILES_ROOT}/scripts/dotfiles/claude-skill-links.sh" --pi-packages)" || return 1
  while IFS= read -r package; do
    [[ -n "${package}" ]] || continue
    run_source_mise exec github:earendil-works/pi -- pi update --extension "${package}" || failed=1
  done <<<"${packages}"
  return "${failed}"
}
