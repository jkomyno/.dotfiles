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

write_mocks() {
  mkdir -p "${check_home}/bin"

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

  cat >"${check_home}/bin/mise" <<'MOCK'
#!/usr/bin/env bash
set -eu
case " $* " in
  *' exec npm:@getpaseo/cli -- paseo --version '*) printf 'paseo test\n' ;;
  *' exec npm:@getpaseo/cli -- paseo daemon status '*) ;;
  *' exec npm:@getpaseo/cli -- paseo daemon pair '*) ;;
  *' exec npm:@agentmemory/agentmemory -- agentmemory --version '*) printf 'agentmemory test\n' ;;
  *) printf 'unexpected mise call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK

  cat >"${check_home}/bin/curl" <<'MOCK'
#!/usr/bin/env sh
exit 0
MOCK

  chmod +x "${check_home}/bin/systemctl" "${check_home}/bin/loginctl" \
    "${check_home}/bin/mise" "${check_home}/bin/curl"
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
    bash "${DOTFILES_ROOT}/${script}" "$@"
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
  mkdir -p "${check_home}/.config/systemd/user"
  export MOCK_SYSTEMCTL_STATE="${check_home}/systemctl.state"
  export MOCK_SYSTEMCTL_LOG="${check_home}/systemctl.log"
  write_mocks

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
      "${DOTFILES_ROOT}/target/home/.config/systemd/user/agentmemory.service"
  fi

  info "service scripts handle mocked systemd start, status, disable, and unavailable-manager states"
}

main "$@"
