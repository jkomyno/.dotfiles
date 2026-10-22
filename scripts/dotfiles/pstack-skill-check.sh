#!/usr/bin/env bash
# Exercise lazy installation and agent dispatch without network or model calls.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly LAUNCHER="${SCRIPT_DIR}/../../target/home/.local/bin/pstack-skill"
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/pstack check.XXXXXX")"
trap 'rm -rf -- "${check_dir}"' EXIT
export XDG_CACHE_HOME="${check_dir}/cache"
export PSTACK_CHECK_LOG="${check_dir}/git.log"
export PSTACK_AGENT_LOG="${check_dir}/agent.log"
mkdir -p "${check_dir}/bin"

cat >"${check_dir}/bin/git" <<'MOCK'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"${PSTACK_CHECK_LOG}"
case "$*" in
  *' init --quiet') ;;
  *' fetch --quiet --depth=1 '*)
    [[ "${PSTACK_FETCH_FAIL:-0}" == 0 ]] || exit 42
    printf '%s\n' "${@: -1}" >"$2/revision"
    ;;
  *' checkout --quiet --detach FETCH_HEAD')
    mkdir -p "$2/skills/how" "$2/skills/poteto-mode" "$2/agents"
    printf 'test how\n' >"$2/skills/how/SKILL.md"
    printf 'test mode\n' >"$2/skills/poteto-mode/SKILL.md"
    ;;
  *' rev-parse HEAD') cat "$2/revision" ;;
  *) printf 'unexpected git call: %s\n' "$*" >&2; exit 1 ;;
esac
MOCK
cat >"${check_dir}/bin/codex" <<'MOCK'
#!/usr/bin/env bash
printf '%s\0' "$@" >"${PSTACK_AGENT_LOG}"
MOCK
chmod +x "${check_dir}/bin/git" "${check_dir}/bin/codex"
cp "${check_dir}/bin/codex" "${check_dir}/bin/pi"
cp "${check_dir}/bin/codex" "${check_dir}/bin/claude"
export PATH="${check_dir}/bin:${PATH}"

bash "${LAUNCHER}" --help >/dev/null
[[ ! -e "${XDG_CACHE_HOME}" && ! -e "${PSTACK_CHECK_LOG}" ]]
if PSTACK_FETCH_FAIL=1 bash "${LAUNCHER}" list >/dev/null 2>&1; then
  printf 'failed fetch unexpectedly succeeded\n' >&2; exit 1
fi
[[ -z "$(ls -A "${XDG_CACHE_HOME}/pstack")" ]]
[[ "$(bash "${LAUNCHER}" list)" == $'how\npoteto-mode' ]]
skill_file="$(bash "${LAUNCHER}" path how)"
[[ -f "${skill_file}" && -d "${skill_file%/skills/how/SKILL.md}/agents" ]]
: >"${PSTACK_CHECK_LOG}"

# shellcheck disable=SC2016 # Verify that task text reaches the agent literally.
task='Explain auth; keep $HOME and `literal` text'
for agent in codex pi claude; do
  bash "${LAUNCHER}" prompt how "${task}" >"${check_dir}/prompt"
  bash "${LAUNCHER}" "${agent}" how "${task}"
  printf '%s\0' "$(<"${check_dir}/prompt")" >"${check_dir}/expected"
  cmp "${check_dir}/expected" "${PSTACK_AGENT_LOG}"
done
[[ ! -s "${PSTACK_CHECK_LOG}" ]]
for invalid in missing ../how --help; do
  if bash "${LAUNCHER}" path "${invalid}" >/dev/null 2>&1; then
    printf 'invalid skill unexpectedly accepted: %s\n' "${invalid}" >&2; exit 1
  fi
done
printf 'ok: pstack lazy installation, offline reuse, and all three agent launchers\n'
