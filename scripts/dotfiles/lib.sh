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
readonly DOTFILES_MISE_PLATFORMS="${DOTFILES_MISE_PLATFORMS:-linux-x64,linux-arm64,macos-arm64,macos-x64}"
readonly DOTFILES_MISE_MINIMUM_RELEASE_AGE="${DOTFILES_MISE_MINIMUM_RELEASE_AGE:-0s}"

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
  if have mise; then
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
    MISE_DEFAULT_CONFIG_FILENAME="config.toml" \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_MISE_CONFIG}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    MISE_IGNORED_CONFIG_PATHS="${HOME}/.config/mise/config.toml:${DOTFILES_ROOT}/mise.toml${MISE_IGNORED_CONFIG_PATHS:+:${MISE_IGNORED_CONFIG_PATHS}}" \
    NPM_CONFIG_UPDATE_NOTIFIER="false" \
    "${mise_cmd}" -C "${DOTFILES_MISE_DIR}" "$@"
}

require_file() {
  local path="$1"
  [[ -e "${path}" ]] || {
    error "missing required file: ${path#"${DOTFILES_ROOT}"/}"
    return 1
  }
}
