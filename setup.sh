#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly DOTFILES_REPO_URL="${DOTFILES_REPO_URL:-https://github.com/jkomyno/.dotfiles}"
readonly DOTFILES_BRANCH="${DOTFILES_BRANCH:-${BRANCH_NAME:-main}}"
readonly DOTFILES_BIN_DIR="${DOTFILES_BIN_DIR:-${HOME}/.local/bin}"
readonly MISE_INSTALL_PATH="${MISE_INSTALL_PATH:-${DOTFILES_BIN_DIR}/mise}"
readonly DOTFILES_ARCHIVE_URL="${DOTFILES_ARCHIVE_URL:-}"
readonly DOTFILES_WORK_DIR="${DOTFILES_WORK_DIR:-${HOME}/work/me}"
readonly DOTFILES_CHECKOUT_DIR="${DOTFILES_CHECKOUT_DIR:-${DOTFILES_WORK_DIR}/dotfiles}"
# Optional GitHub token for bootstrapping a private repo. When set, the initial
# clone and archive fetch authenticate with it; leave it empty for a public
# repo. Falls back to the conventional GH_TOKEN / GITHUB_TOKEN names.
readonly DOTFILES_GITHUB_TOKEN="${DOTFILES_GITHUB_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"
readonly DEFAULT_DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro"

export DOTFILES_WORK_DIR
export DOTFILES_CHECKOUT_DIR

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

dotfiles_checkout_kind=""

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

has_working_git() {
  command -v git >/dev/null 2>&1 || return 1

  if [[ "$(uname -s)" == "Darwin" ]] && ! xcode-select -p >/dev/null 2>&1; then
    return 1
  fi

  git --version >/dev/null 2>&1
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

cleanup_sudo_macos() {
  if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
    kill "${SUDO_KEEPALIVE_PID}" >/dev/null 2>&1 || true
  fi

  # Invalidate the cached sudo timestamp so elevated access does not outlive
  # the bootstrap.
  sudo -k >/dev/null 2>&1 || true
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
  # Prime sudo's own timestamp with a single interactive prompt, then keep it
  # warm in the background. The password is never read into a shell variable,
  # written to a temp file, or stored in the keychain, so it cannot leak via
  # `set -x`, argv, or a readable credential at rest. Later privileged steps
  # rely on sudo's per-tty timestamp cache, which the loop below refreshes.
  if ! sudo -v; then
    die "could not obtain sudo access"
  fi

  trap cleanup_sudo_macos EXIT

  while true; do
    sudo -n -v >/dev/null 2>&1 || exit
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
  sudo scutil --set "${key}" "${value}"
}

configure_macos_computer_name() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  # Machine identity is setup-time state. Keep it out of repeatable defaults
  # so a later apply cannot unexpectedly rename a Mac.
  if [[ "${CI:-}" == "true" ]]; then
    log "Skipping computer name setup in CI"
    return 0
  fi

  if ! sudo -n -v 2>/dev/null && ! has_tty; then
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
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${netbios_name}"
}

checkout_is_git() {
  [[ -d "${DOTFILES_CHECKOUT_DIR}/.git" ]]
}

checkout_is_source_tree() {
  [[ -f "${DOTFILES_CHECKOUT_DIR}/setup.sh" && -f "${DOTFILES_CHECKOUT_DIR}/mise.toml" && -d "${DOTFILES_CHECKOUT_DIR}/scripts/dotfiles" ]]
}

is_empty_dir() {
  local path="$1"
  [[ -d "${path}" ]] || return 1
  [[ -z "$(find "${path}" -mindepth 1 -maxdepth 1 -print -quit)" ]]
}

prepare_dotfiles_parent() {
  local checkout_parent
  checkout_parent="$(dirname -- "${DOTFILES_CHECKOUT_DIR}")"

  mkdir -p "${DOTFILES_WORK_DIR}"
  mkdir -p "${checkout_parent}"

  if [[ -e "${DOTFILES_CHECKOUT_DIR}" && ! -d "${DOTFILES_CHECKOUT_DIR}" ]]; then
    die "DOTFILES_CHECKOUT_DIR exists but is not a directory: ${DOTFILES_CHECKOUT_DIR}"
  fi
}

dotfiles_archive_url() {
  if [[ -n "${DOTFILES_ARCHIVE_URL}" ]]; then
    printf '%s\n' "${DOTFILES_ARCHIVE_URL}"
    return
  fi

  local repo_url="${DOTFILES_REPO_URL%.git}"
  local repo_path=""

  case "${repo_url}" in
    https://github.com/*)
      repo_path="${repo_url#https://github.com/}"
      ;;
    git@github.com:*)
      repo_path="${repo_url#git@github.com:}"
      ;;
    *)
      return 1
      ;;
  esac

  [[ "${repo_path}" == */* ]] || return 1

  if [[ -n "${DOTFILES_GITHUB_TOKEN}" ]]; then
    # api.github.com honors a Bearer token for private repos and 302-redirects
    # to a pre-signed codeload URL (curl -L follows and drops the auth header
    # across the host boundary, which is what we want).
    printf 'https://api.github.com/repos/%s/tarball/%s\n' "${repo_path}" "${DOTFILES_BRANCH}"
  else
    printf 'https://codeload.github.com/%s/tar.gz/refs/heads/%s\n' "${repo_path}" "${DOTFILES_BRANCH}"
  fi
}

clone_dotfiles_checkout() {
  if [[ -e "${DOTFILES_CHECKOUT_DIR}" ]]; then
    if is_empty_dir "${DOTFILES_CHECKOUT_DIR}"; then
      rmdir "${DOTFILES_CHECKOUT_DIR}"
    else
      return 1
    fi
  fi

  log "Cloning dotfiles from ${DOTFILES_REPO_URL}#${DOTFILES_BRANCH} into ${DOTFILES_CHECKOUT_DIR}"

  # For a private HTTPS clone, pass the token as a one-shot Basic auth header via
  # `-c` so it is used for this invocation only and never written to
  # .git/config. The array is expanded 3.2-safely (empty when public).
  local -a git_auth=()
  if [[ -n "${DOTFILES_GITHUB_TOKEN}" && "${DOTFILES_REPO_URL}" == https://* ]]; then
    local auth_basic
    auth_basic="$(printf 'x-access-token:%s' "${DOTFILES_GITHUB_TOKEN}" | base64 | tr -d '\n')"
    git_auth=(-c "http.extraHeader=Authorization: Basic ${auth_basic}")
  fi

  git ${git_auth[@]+"${git_auth[@]}"} clone --branch "${DOTFILES_BRANCH}" --single-branch "${DOTFILES_REPO_URL}" "${DOTFILES_CHECKOUT_DIR}"
}

download_dotfiles_archive() {
  local archive_url
  archive_url="$(dotfiles_archive_url)" || {
    die "git is unavailable and DOTFILES_REPO_URL cannot be converted to an archive URL; set DOTFILES_ARCHIVE_URL"
  }

  if [[ -e "${DOTFILES_CHECKOUT_DIR}" ]]; then
    if is_empty_dir "${DOTFILES_CHECKOUT_DIR}"; then
      rmdir "${DOTFILES_CHECKOUT_DIR}"
    else
      die "cannot download archive into non-empty checkout: ${DOTFILES_CHECKOUT_DIR}"
    fi
  fi

  local tmp_dir archive_file extract_dir
  tmp_dir="$(mktemp -d)"
  archive_file="${tmp_dir}/dotfiles.tar.gz"
  extract_dir="${tmp_dir}/extract"
  mkdir -p "${extract_dir}"

  log "Downloading dotfiles archive from ${archive_url}"
  local -a curl_auth=()
  if [[ -n "${DOTFILES_GITHUB_TOKEN}" ]]; then
    curl_auth=(-H "Authorization: Bearer ${DOTFILES_GITHUB_TOKEN}")
  fi
  curl -fsSL ${curl_auth[@]+"${curl_auth[@]}"} "${archive_url}" -o "${archive_file}"
  tar -xzf "${archive_file}" -C "${extract_dir}" --strip-components 1
  mv "${extract_dir}" "${DOTFILES_CHECKOUT_DIR}"
  rm -rf "${tmp_dir}"
}

prepare_dotfiles_checkout() {
  prepare_dotfiles_parent

  if checkout_is_git; then
    dotfiles_checkout_kind="git"
    log "Using existing git checkout at ${DOTFILES_CHECKOUT_DIR}"
    return
  fi

  if checkout_is_source_tree; then
    dotfiles_checkout_kind="source"
    log "Using existing source tree at ${DOTFILES_CHECKOUT_DIR}"
    return
  fi

  if has_working_git; then
    clone_dotfiles_checkout || die "checkout path is not empty and is not a dotfiles source tree: ${DOTFILES_CHECKOUT_DIR}"
    dotfiles_checkout_kind="git"
    return
  fi

  download_dotfiles_archive
  dotfiles_checkout_kind="archive"
}

ensure_mise() {
  local install_script="${DOTFILES_CHECKOUT_DIR}/install/common/mise.sh"
  [[ -f "${install_script}" ]] || die "missing mise installer: ${install_script}"

  bash "${install_script}" --binary-only

  local mise_cmd=""
  if [[ -x "${MISE_INSTALL_PATH}" ]]; then
    mise_cmd="${MISE_INSTALL_PATH}"
  elif command -v mise >/dev/null 2>&1; then
    mise_cmd="$(command -v mise)"
  else
    die "mise install did not create ${MISE_INSTALL_PATH}"
  fi

  MISE_EXPERIMENTAL=true "${mise_cmd}" dotfiles status --help >/dev/null 2>&1 ||
    die "mise at ${mise_cmd} does not expose the experimental dotfiles command"

  printf '%s\n' "${mise_cmd}"
}

run_mise_staged_setup() {
  local setup_runner="${DOTFILES_CHECKOUT_DIR}/scripts/dotfiles/mise-setup-staged.sh"
  [[ -f "${setup_runner}" ]] || die "missing staged setup runner: ${setup_runner}"

  bash "${setup_runner}" "$@"
}

promote_archive_checkout_to_git() {
  [[ "${dotfiles_checkout_kind}" == "archive" ]] || return 0

  has_working_git || die "git is still unavailable after Command Line Tools setup"

  local backup_dir
  backup_dir="${DOTFILES_CHECKOUT_DIR}.archive.$(date +%Y%m%d%H%M%S)"

  log "Replacing bootstrap archive with a git checkout"
  mv "${DOTFILES_CHECKOUT_DIR}" "${backup_dir}"

  if clone_dotfiles_checkout; then
    rm -rf "${backup_dir}"
    dotfiles_checkout_kind="git"
    return
  fi

  rm -rf "${DOTFILES_CHECKOUT_DIR}"
  mv "${backup_dir}" "${DOTFILES_CHECKOUT_DIR}"
  die "failed to replace bootstrap archive with a git checkout"
}

run_mise_setup() {
  prepare_dotfiles_checkout

  local mise_cmd
  mise_cmd="$(ensure_mise)"
  export PATH="$(dirname -- "${mise_cmd}"):${PATH}"

  local -a setup_args=()
  if [[ "${DOTFILES_SETUP_FORCE_DOTFILES:-}" == "1" ]]; then
    setup_args+=(--force-dotfiles)
  fi

  # Expand a possibly-empty array in a way that is safe under `set -u` on the
  # stock macOS /bin/bash 3.2, where a bare "${arr[@]}" on an empty array aborts
  # with "unbound variable". This is the shell a blank Mac runs setup.sh under.
  if [[ "${dotfiles_checkout_kind}" == "archive" ]]; then
    run_mise_staged_setup ${setup_args[@]+"${setup_args[@]}"} --until install:macos:command-line-tools
    promote_archive_checkout_to_git
    run_mise_staged_setup ${setup_args[@]+"${setup_args[@]}"} --from install:macos:homebrew
    return
  fi

  run_mise_staged_setup ${setup_args[@]+"${setup_args[@]}"}
}

persist_repo_mise_trust() {
  # Setup runs mise with an ephemeral MISE_TRUSTED_CONFIG_PATHS, which does not
  # persist. Mark this repo's config trusted so post-setup maintenance commands
  # (`just diff`, `mise dotfiles apply`, `mise dotfiles status`) work without a
  # manual `mise trust`. Runs after the checkout is final (archive->git
  # promotion included).
  command -v mise >/dev/null 2>&1 || return 0
  mise trust "${DOTFILES_CHECKOUT_DIR}/mise.toml" >/dev/null 2>&1 || true
}

main() {
  printf '%s\n' "${DOTFILES_LOGO}"
  require_command curl

  keepalive_sudo
  configure_macos_computer_name

  run_mise_setup
  persist_repo_mise_trust

  log "Done"
}

main "$@"
