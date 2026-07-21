#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

fixture_root=""
fixture_home=""
fixture_bin=""
fixture_log=""

cleanup() {
  [[ -z "${fixture_root}" ]] || rm -rf "${fixture_root}"
}

write_executable() {
  local path="$1"
  shift
  printf '%s\n' "$@" >"${path}"
  chmod +x "${path}"
}

prepare_fixture() {
  fixture_root="$(mktemp -d)"
  fixture_home="${fixture_root}/home"
  fixture_bin="${fixture_root}/bin"
  fixture_log="${fixture_root}/calls.log"

  mkdir -p \
    "${fixture_home}" \
    "${fixture_bin}" \
    "${fixture_root}/repo/scripts/dotfiles" \
    "${fixture_root}/repo/install/common"

  cp "${SCRIPT_DIR}/update.sh" "${fixture_root}/repo/scripts/dotfiles/update.sh"
  cp "${SCRIPT_DIR}/lib.sh" "${fixture_root}/repo/scripts/dotfiles/lib.sh"

  write_executable "${fixture_bin}/git" \
    '#!/usr/bin/env bash' \
    'printf "git:%s\n" "$*" >>"${UPDATE_CHECK_LOG}"'
  write_executable "${fixture_bin}/mise" \
    '#!/usr/bin/env bash' \
    'printf "mise:%s\n" "$*" >>"${UPDATE_CHECK_LOG}"'
  write_executable "${fixture_root}/repo/scripts/dotfiles/versions.sh" \
    '#!/usr/bin/env bash' \
    'printf "versions:%s\n" "$*" >>"${UPDATE_CHECK_LOG}"'
  write_executable "${fixture_root}/repo/install/common/agents.sh" \
    '#!/usr/bin/env bash' \
    'printf "agents:%s\n" "${*:-install}" >>"${UPDATE_CHECK_LOG}"' \
    '[[ "${AGENT_STUB_FAIL:-0}" != 1 ]]'
}

run_update() {
  env \
    HOME="${fixture_home}" \
    DOTFILES="${fixture_root}/repo" \
    PATH="${fixture_bin}:/usr/bin:/bin" \
    UPDATE_CHECK_LOG="${fixture_log}" \
    /bin/bash "${fixture_root}/repo/scripts/dotfiles/update.sh" "$@"
}

line_number() {
  local pattern="$1"
  grep -nF "${pattern}" "${fixture_log}" | head -n 1 | cut -d: -f1
}

assert_before() {
  local first="$1" second="$2" first_line second_line
  first_line="$(line_number "${first}")"
  second_line="$(line_number "${second}")"
  if [[ -z "${first_line}" || -z "${second_line}" || "${first_line}" -ge "${second_line}" ]]; then
    error "update flow order mismatch: expected '${first}' before '${second}'"
    return 1
  fi
}

check_standalone_self() {
  : >"${fixture_log}"
  run_update self
  assert_before "mise:-C ${fixture_root}/repo dotfiles apply --yes" "agents:install"

  : >"${fixture_log}"
  run_update --check self
  assert_before "mise:-C ${fixture_root}/repo dotfiles apply --dry-run" "agents:--check"
}

check_all_order() {
  : >"${fixture_log}"
  run_update all
  assert_before "versions:--write" "mise:-C ${fixture_root}/repo dotfiles apply --yes"
  assert_before "mise:-C ${fixture_root}/repo dotfiles apply --yes" "agents:--update"
}

check_failure_status() {
  : >"${fixture_log}"
  if AGENT_STUB_FAIL=1 run_update self >"${fixture_root}/failure.out" 2>&1; then
    error "standalone self update hid an adapter failure"
    return 1
  fi
  grep -qF "update completed with 1 failed component(s)" "${fixture_root}/failure.out"
}

check_missing_jq_status() {
  local agent_root="${fixture_root}/agent-root"
  mkdir -p "${agent_root}/scripts/dotfiles"
  printf '{}\n' >"${agent_root}/scripts/dotfiles/agent-plugins.json"
  write_executable "${agent_root}/scripts/dotfiles/claude-skill-links.sh" \
    '#!/usr/bin/env bash' \
    'exit 1'

  if env \
    HOME="${fixture_home}" \
    DOTFILES="${agent_root}" \
    PATH="/usr/bin:/bin" \
    /bin/bash "${DOTFILES_ROOT}/install/common/agents.sh" >"${fixture_root}/missing-jq.out" 2>&1; then
    error "agent installer hid a skill-link failure when jq was unavailable"
    return 1
  fi
  grep -qF "declared agent state not fully reproduced" "${fixture_root}/missing-jq.out"
}

main() {
  trap cleanup EXIT
  prepare_fixture
  check_standalone_self
  check_all_order
  check_failure_status
  check_missing_jq_status
  info "update flow preserves adapter ordering and propagates failures"
}

main "$@"
