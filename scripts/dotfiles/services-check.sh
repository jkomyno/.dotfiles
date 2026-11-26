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
  ' x mr-boxington -- mbx --version ') printf 'mbx test\n' ;;
  ' x mr-boxington -- mbx gc '* )
    [[ "${MOCK_CLEANER_FAIL:-0}" != "1" ]] || exit 42
    ;;
  *) printf 'unexpected mise call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK

  chmod +x "${check_home}/bin/mise"
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

run_rust_cache_maintenance() {
  HOME="${check_home}" \
    PATH="${check_home}/bin:/usr/bin:/bin" \
    MISE_INSTALL_PATH="${check_home}/bin/mise" \
    bash "${DOTFILES_ROOT}/target/home/.local/bin/rust-cache-maintenance" "$@"
}

check_rust_cache_maintenance() {
  : >"${MOCK_MISE_LOG}"
  run_rust_cache_maintenance --check >/dev/null
  grep -Fxq -- "x mr-boxington -- mbx --version" "${MOCK_MISE_LOG}"

  : >"${MOCK_MISE_LOG}"
  run_rust_cache_maintenance --dry-run
  grep -Fxq -- "x mr-boxington -- mbx gc --dry-run" "${MOCK_MISE_LOG}"

  : >"${MOCK_MISE_LOG}"
  run_rust_cache_maintenance --scheduled
  grep -Fxq -- "x mr-boxington -- mbx gc" "${MOCK_MISE_LOG}"

  if MOCK_CLEANER_FAIL=1 run_rust_cache_maintenance --apply >/dev/null 2>&1; then
    error "expected mbx failure to fail Rust cache maintenance"
    return 1
  fi

  cat >"${check_home}/bin/mbx" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${MOCK_MBX_LOG}"
MOCK
  chmod +x "${check_home}/bin/mbx"
  : >"${MOCK_MBX_LOG}"
  : >"${MOCK_MISE_LOG}"
  run_rust_cache_maintenance --check
  run_rust_cache_maintenance --dry-run
  grep -Fxq -- "--version" "${MOCK_MBX_LOG}"
  grep -Fxq -- "gc --dry-run" "${MOCK_MBX_LOG}"
  [[ ! -s "${MOCK_MISE_LOG}" ]]
  rm "${check_home}/bin/mbx"
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

check_work_service() {
  local unit="${check_home}/.config/systemd/user/paseo.service"
  printf '[Unit]\nDescription=Enrolled work host\n' >"${unit}"
  printf 'active\n' >"${MOCK_SYSTEMCTL_STATE}"
  : >"${MOCK_SYSTEMCTL_LOG}"

  MOCK_UNAME=Linux DOTFILES_SELECTION=work run_service "install/common/paseo.sh" >/dev/null
  grep -Fxq 'Description=Enrolled work host' "${unit}"
  assert_state active
  if grep -Eq -- 'daemon-reload|--now|restart|disable' "${MOCK_SYSTEMCTL_LOG}"; then
    error "work provisioning changed the enrolled Paseo service"
    return 1
  fi
  rm -- "${unit}"
}

main() {
  trap cleanup EXIT
  check_home="$(mktemp -d)"
  export MOCK_SYSTEMCTL_STATE="${check_home}/systemctl.state"
  export MOCK_SYSTEMCTL_LOG="${check_home}/systemctl.log"
  export MOCK_MISE_LOG="${check_home}/mise.log"
  export MOCK_MBX_LOG="${check_home}/mbx.log"
  export MOCK_LAUNCHCTL_STATE="${check_home}/launchctl.state"
  export MOCK_LAUNCHCTL_LOG="${check_home}/launchctl.log"
  write_common_mocks
  check_rust_cache_maintenance
  write_systemd_mocks
  write_launchd_mocks
  check_rust_cache_installer
  check_work_service

  # paseo.sh only drives systemctl on Linux (main() branches
  # on `uname -s`; Darwin uses launchctl/a tracked LaunchAgent instead), so the
  # systemd mocks below have nothing to assert against on macOS runners.
  if [[ "$(uname -s)" != "Linux" ]]; then
    info "skipping systemd user-service checks on $(uname -s); paseo.sh uses launchctl here"
    return 0
  fi

  check_one_service \
    "install/common/paseo.sh" \
    "paseo.service" \
    "target/home/.config/systemd/user/paseo-mise.service"

  MOCK_SYSTEMCTL_AVAILABLE=0 run_service "install/common/paseo.sh" >/dev/null 2>&1

  if command -v systemd-analyze >/dev/null 2>&1; then
    systemd-analyze --user verify \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/paseo-mise.service" \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/rust-cache-maintenance.service" \
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/rust-cache-maintenance.timer"
  fi

  info "service scripts handle mocked systemd start, status, disable, and unavailable-manager states"
}

main "$@"
