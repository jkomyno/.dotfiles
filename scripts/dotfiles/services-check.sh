#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

check_home=""

cleanup() {
  [[ -z "${check_home}" ]] || rm -rf "${check_home}"
}

assert_state() {
  local expected="$1"
  if [[ "$(<"${MOCK_SYSTEMCTL_STATE}")" != "${expected}" ]]; then
    error "expected mocked systemd state ${expected}"
    return 1
  fi
}

write_common_mocks() {
  mkdir -p "${check_home}/bin"

  cat >"${check_home}/bin/mise" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"${MOCK_MISE_LOG:-/dev/null}"
case " $* " in
  *' exec npm:@getpaseo/cli -- paseo --version '*) printf 'paseo test\n' ;;
  *' exec npm:@getpaseo/cli -- paseo daemon status '*) ;;
  *' exec npm:@getpaseo/cli -- paseo daemon pair '*) ;;
  *' exec npm:@agentmemory/agentmemory -- agentmemory --version '*) printf 'agentmemory test\n' ;;
  *' exec cargo:cargo-clean-all -- cargo-clean-all '*)
    if [[ "$*" == *' --yes '* && "${MOCK_CLEANER_FAIL:-0}" == "1" ]]; then
      exit 42
    fi
    ;;
  *) printf 'unexpected mise call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK

  cat >"${check_home}/bin/rustc" <<'MOCK'
#!/usr/bin/env sh
printf 'rustc %s\n' "$*" >>"${MOCK_RUSTC_LOG}"
MOCK

  chmod +x "${check_home}/bin/mise" "${check_home}/bin/rustc"
}

write_systemd_mocks() {
  mkdir -p "${check_home}/.config/systemd/user"

  cat >"${check_home}/bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"${MOCK_SYSTEMCTL_LOG}"
case "$*" in
  '--user show-environment') [[ "${MOCK_SYSTEMCTL_AVAILABLE:-1}" == "1" ]] ;;
  '--user is-active --quiet '*) [[ "$(<"${MOCK_SYSTEMCTL_STATE}")" == "active" ]] ;;
  '--user enable --now '* | '--user restart '*) printf 'active\n' >"${MOCK_SYSTEMCTL_STATE}" ;;
  '--user disable --now '*) printf 'inactive\n' >"${MOCK_SYSTEMCTL_STATE}" ;;
  '--user daemon-reload') ;;
  *) printf 'unexpected systemctl call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK

  cat >"${check_home}/bin/loginctl" <<'MOCK'
#!/usr/bin/env sh
case "$*" in
  'show-user '*'-p Linger --value') printf 'yes\n' ;;
  'enable-linger '*) ;;
  *) exit 1 ;;
esac
MOCK

  cat >"${check_home}/bin/curl" <<'MOCK'
#!/usr/bin/env sh
exit 0
MOCK

  chmod +x "${check_home}/bin/systemctl" "${check_home}/bin/loginctl" "${check_home}/bin/curl"
}

write_launchd_mocks() {
  cat >"${check_home}/bin/launchctl" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"${MOCK_LAUNCHCTL_LOG}"
case "$1" in
  print) [[ "$(<"${MOCK_LAUNCHCTL_STATE}")" == "active" ]] ;;
  bootstrap | asuser) printf 'active\n' >"${MOCK_LAUNCHCTL_STATE}" ;;
  bootout) printf 'inactive\n' >"${MOCK_LAUNCHCTL_STATE}" ;;
  enable) ;;
  *) printf 'unexpected launchctl call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK

  cat >"${check_home}/bin/uname" <<'MOCK'
#!/usr/bin/env sh
if [ "${1:-}" = "-s" ] && [ -n "${MOCK_UNAME:-}" ]; then
  printf '%s\n' "${MOCK_UNAME}"
else
  /usr/bin/uname "$@"
fi
MOCK

  chmod +x "${check_home}/bin/launchctl" "${check_home}/bin/uname"
}

check_rustc_cache_wrapper() {
  : >"${MOCK_RUSTC_LOG}"
  HOME="${check_home}" \
    PATH="${check_home}/bin:/usr/bin:/bin" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    bash "${DOTFILES_ROOT}/target/home/.local/bin/rustc-cache-wrapper" \
    "${check_home}/bin/rustc" --version
  grep -Fq -- "rustc --version" "${MOCK_RUSTC_LOG}"

  cat >"${check_home}/bin/sccache" <<'MOCK'
#!/usr/bin/env sh
printf 'sccache %s\n' "$*" >>"${MOCK_SCCACHE_LOG}"
MOCK
  chmod +x "${check_home}/bin/sccache"
  : >"${MOCK_SCCACHE_LOG}"
  HOME="${check_home}" \
    PATH="${check_home}/bin:/usr/bin:/bin" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    bash "${DOTFILES_ROOT}/target/home/.local/bin/rustc-cache-wrapper" \
    "${check_home}/bin/rustc" --version
  grep -Fq -- "sccache ${check_home}/bin/rustc --version" "${MOCK_SCCACHE_LOG}"
}

run_rust_cache_maintenance() {
  HOME="${check_home}" \
    XDG_STATE_HOME="${check_home}/.local/state" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    bash "${DOTFILES_ROOT}/target/home/.local/bin/rust-cache-maintenance" "$@"
}

assert_maintenance_rejected() {
  local expected="$1"
  local output
  shift

  : >"${MOCK_MISE_LOG}"
  if output="$(env "$@" \
    HOME="${check_home}" \
    XDG_STATE_HOME="${check_home}/.local/state" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    bash "${DOTFILES_ROOT}/target/home/.local/bin/rust-cache-maintenance" --apply 2>&1)"; then
    error "expected Rust cache maintenance to reject unsafe configuration"
    return 1
  fi
  grep -Fq -- "${expected}" <<<"${output}"
  [[ ! -s "${MOCK_MISE_LOG}" ]]
}

check_rust_cache_maintenance() {
  local output

  mkdir -p "${check_home}/work"
  : >"${MOCK_MISE_LOG}"

  run_rust_cache_maintenance --check
  grep -Fq -- "exec cargo:cargo-clean-all -- cargo-clean-all --version" "${MOCK_MISE_LOG}"
  : >"${MOCK_MISE_LOG}"

  output="$({
    run_rust_cache_maintenance --dry-run
  } 2>&1)"

  grep -Fq "Previewing Cargo targets unused for 30 days under ${check_home}/work" <<<"${output}"
  grep -Fq -- "exec cargo:cargo-clean-all -- cargo-clean-all --dry-run --keep-days 30 ${check_home}/work" "${MOCK_MISE_LOG}"

  : >"${MOCK_MISE_LOG}"
  RUST_TARGET_KEEP_DAYS=14 run_rust_cache_maintenance --scheduled >/dev/null
  grep -Fq -- "exec cargo:cargo-clean-all -- cargo-clean-all --yes --keep-days 14 ${check_home}/work" "${MOCK_MISE_LOG}"

  : >"${MOCK_MISE_LOG}"
  RUST_TARGET_KEEP_DAYS=14 run_rust_cache_maintenance --scheduled >/dev/null
  [[ ! -s "${MOCK_MISE_LOG}" ]]

  touch -t 200001010000 "${check_home}/.local/state/rust-cache-maintenance/last-run"
  RUST_TARGET_KEEP_DAYS=14 run_rust_cache_maintenance --scheduled >/dev/null
  grep -Fq -- "exec cargo:cargo-clean-all -- cargo-clean-all --yes --keep-days 14 ${check_home}/work" "${MOCK_MISE_LOG}"

  mkdir "${check_home}/.local/state/rust-cache-maintenance/lock"
  touch -t 200001010000 "${check_home}/.local/state/rust-cache-maintenance/lock"
  : >"${MOCK_MISE_LOG}"
  run_rust_cache_maintenance --apply >/dev/null
  grep -Fq -- "exec cargo:cargo-clean-all -- cargo-clean-all --yes --keep-days 30 ${check_home}/work" "${MOCK_MISE_LOG}"

  assert_maintenance_rejected "refusing broad Rust workspace root" "RUST_TARGET_CLEAN_ROOT=${check_home}"
  assert_maintenance_rejected "refusing broad Rust workspace root" "RUST_TARGET_CLEAN_ROOT=/"
  assert_maintenance_rejected "refusing broad Rust workspace root" "RUST_TARGET_CLEAN_ROOT=${check_home}/work/.."
  assert_maintenance_rejected "RUST_TARGET_KEEP_DAYS must be a positive integer" "RUST_TARGET_KEEP_DAYS=0"
  assert_maintenance_rejected "RUST_TARGET_KEEP_DAYS must be a positive integer" "RUST_TARGET_KEEP_DAYS=invalid"

  rm -f "${check_home}/.local/state/rust-cache-maintenance/last-run"
  if MOCK_CLEANER_FAIL=1 run_rust_cache_maintenance --scheduled >/dev/null 2>&1; then
    error "expected a cleaner failure to fail Rust cache maintenance"
    return 1
  fi
  [[ ! -e "${check_home}/.local/state/rust-cache-maintenance/last-run" ]]
  [[ ! -e "${check_home}/.local/state/rust-cache-maintenance/lock" ]]
}

run_service() {
  local script="$1"
  shift
  HOME="${check_home}" \
    PATH="${check_home}/bin:/usr/bin:/bin" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    MOCK_SYSTEMCTL_STATE="${MOCK_SYSTEMCTL_STATE}" \
    MOCK_SYSTEMCTL_LOG="${MOCK_SYSTEMCTL_LOG}" \
    MOCK_SYSTEMCTL_AVAILABLE="${MOCK_SYSTEMCTL_AVAILABLE:-1}" \
    MOCK_LAUNCHCTL_STATE="${MOCK_LAUNCHCTL_STATE}" \
    MOCK_LAUNCHCTL_LOG="${MOCK_LAUNCHCTL_LOG}" \
    MOCK_UNAME="${MOCK_UNAME:-}" \
    bash "${DOTFILES_ROOT}/${script}" "$@"
}

check_rust_cache_installer() {
  local label="com.jkomyno.rust-cache-maintenance"
  local timer="rust-cache-maintenance.timer"

  mkdir -p "${check_home}/.local/bin" "${check_home}/Library/LaunchAgents"
  ln -s "${DOTFILES_ROOT}/target/home/.local/bin/rust-cache-maintenance" \
    "${check_home}/.local/bin/rust-cache-maintenance"
  ln -s "${DOTFILES_ROOT}/target/home/.config/systemd/user/rust-cache-maintenance.service" \
    "${check_home}/.config/systemd/user/rust-cache-maintenance.service"
  ln -s "${DOTFILES_ROOT}/target/home/.config/systemd/user/${timer}" \
    "${check_home}/.config/systemd/user/${timer}"
  ln -s "${DOTFILES_ROOT}/target/home/Library/LaunchAgents/${label}.plist" \
    "${check_home}/Library/LaunchAgents/${label}.plist"

  printf 'inactive\n' >"${MOCK_SYSTEMCTL_STATE}"
  : >"${MOCK_SYSTEMCTL_LOG}"
  MOCK_UNAME=Linux run_service "install/common/rust-cache.sh" >/dev/null
  MOCK_UNAME=Linux run_service "install/common/rust-cache.sh" --status >/dev/null
  MOCK_UNAME=Linux run_service "install/common/rust-cache.sh" --remove >/dev/null
  assert_state inactive
  grep -Fq -- "--user daemon-reload" "${MOCK_SYSTEMCTL_LOG}"
  grep -Fq -- "--user enable --now ${timer}" "${MOCK_SYSTEMCTL_LOG}"
  grep -Fq -- "--user disable --now ${timer}" "${MOCK_SYSTEMCTL_LOG}"

  printf 'inactive\n' >"${MOCK_LAUNCHCTL_STATE}"
  : >"${MOCK_LAUNCHCTL_LOG}"
  MOCK_UNAME=Darwin run_service "install/common/rust-cache.sh" >/dev/null
  MOCK_UNAME=Darwin run_service "install/common/rust-cache.sh" --status >/dev/null
  MOCK_UNAME=Darwin run_service "install/common/rust-cache.sh" --remove >/dev/null
  [[ "$(<"${MOCK_LAUNCHCTL_STATE}")" == "inactive" ]]
  grep -Fq -- "bootstrap gui/$(id -u) ${check_home}/Library/LaunchAgents/${label}.plist" "${MOCK_LAUNCHCTL_LOG}"
  grep -Fq -- "print gui/$(id -u)/${label}" "${MOCK_LAUNCHCTL_LOG}"
  grep -Fq -- "bootout gui/$(id -u)/${label}" "${MOCK_LAUNCHCTL_LOG}"
}

check_one_service() {
  local script="$1"
  local unit="$2"
  local source="$3"

  ln -s "${DOTFILES_ROOT}/${source}" "${check_home}/.config/systemd/user/${unit}"
  printf 'inactive\n' >"${MOCK_SYSTEMCTL_STATE}"
  : >"${MOCK_SYSTEMCTL_LOG}"

  run_service "${script}" >/dev/null
  assert_state active
  run_service "${script}" --status >/dev/null
  run_service "${script}" --remove >/dev/null
  assert_state inactive

  grep -Fq -- "--user enable --now ${unit}" "${MOCK_SYSTEMCTL_LOG}"
  grep -Fq -- "--user restart ${unit}" "${MOCK_SYSTEMCTL_LOG}"
  grep -Fq -- "--user disable --now ${unit}" "${MOCK_SYSTEMCTL_LOG}"
}

main() {
  trap cleanup EXIT
  check_home="$(mktemp -d)"
  export MOCK_SYSTEMCTL_STATE="${check_home}/systemctl.state"
  export MOCK_SYSTEMCTL_LOG="${check_home}/systemctl.log"
  export MOCK_MISE_LOG="${check_home}/mise.log"
  export MOCK_RUSTC_LOG="${check_home}/rustc.log"
  export MOCK_SCCACHE_LOG="${check_home}/sccache.log"
  export MOCK_LAUNCHCTL_STATE="${check_home}/launchctl.state"
  export MOCK_LAUNCHCTL_LOG="${check_home}/launchctl.log"
  write_common_mocks
  check_rustc_cache_wrapper
  check_rust_cache_maintenance
  write_systemd_mocks
  write_launchd_mocks
  check_rust_cache_installer

  # paseo.sh and agentmemory.sh only drive systemctl on Linux (main() branches
  # on `uname -s`; Darwin uses launchctl/a tracked LaunchAgent instead), so the
  # systemd mocks below have nothing to assert against on macOS runners.
  if [[ "$(uname -s)" != "Linux" ]]; then
    info "skipping systemd user-service checks on $(uname -s); paseo.sh/agentmemory.sh use launchctl here"
    return 0
  fi

  check_one_service \
    "install/common/paseo.sh" \
    "paseo.service" \
    "target/home/.config/systemd/user/paseo.service"
  check_one_service \
    "install/common/agentmemory.sh" \
    "agentmemory.service" \
    "target/home/.config/systemd/user/agentmemory.service"

  MOCK_SYSTEMCTL_AVAILABLE=0 run_service "install/common/paseo.sh" >/dev/null 2>&1

  if command -v systemd-analyze >/dev/null 2>&1; then
    systemd-analyze --user verify \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/paseo.service" \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/agentmemory.service" \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/rust-cache-maintenance.service" \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/rust-cache-maintenance.timer"
  fi

  info "service scripts handle mocked systemd start, status, disable, and unavailable-manager states"
}

main "$@"
