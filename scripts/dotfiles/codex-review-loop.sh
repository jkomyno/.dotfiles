#!/usr/bin/env bash
# codex-review-loop.sh — drive Codex as an adversarial reviewer of a branch.
#
# Runs `codex exec` non-interactively against the changes on the current git
# branch relative to a base ref, asking Codex to critique them (review-only,
# no edits) and emit structured findings as JSON. A human or a second agent
# then adversarially verifies each finding, fixes the real ones, and re-runs
# until the findings converge to noise.
#
# By default Codex runs with a read-only sandbox (-s read-only): it can read the
# repo and run analysis (git diff, shellcheck) but cannot modify files, HOME
# state, or credentials, even if a model command misfires. Pass --danger to use
# --dangerously-bypass-approvals-and-sandbox instead (no sandbox, no prompts);
# only do that on a committed branch you can fully recover. The run refuses to
# start on a dirty working tree so uncommitted work is never at risk.
#
# Usage:
#   scripts/dotfiles/codex-review-loop.sh [--base REF] [--out DIR] [--model M] [--danger]
#
# Outputs (under --out, default: a scratch dir printed at the end):
#   findings.json   structured findings from Codex
#   last-message.md Codex's final narrative message
#   review-prompt.txt the exact prompt sent

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

BASE_REF="main"
OUT_DIR=""
MODEL=""
DANGER=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --danger)
      DANGER=true
      shift
      ;;
    --base)
      [[ $# -ge 2 ]] || {
        error "--base needs a value"
        exit 2
      }
      BASE_REF="$2"
      shift 2
      ;;
    --out)
      [[ $# -ge 2 ]] || {
        error "--out needs a value"
        exit 2
      }
      OUT_DIR="$2"
      shift 2
      ;;
    --model)
      [[ $# -ge 2 ]] || {
        error "--model needs a value"
        exit 2
      }
      MODEL="$2"
      shift 2
      ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      error "unknown argument: $1"
      exit 2
      ;;
  esac
done

codex_bin() {
  if have codex; then
    command -v codex
  elif [[ -x "${HOME}/.bun/bin/codex" ]]; then
    printf '%s\n' "${HOME}/.bun/bin/codex"
  else
    return 1
  fi
}

CODEX="$(codex_bin)" || {
  error "codex CLI not found (install via mise: npm:@openai/codex)"
  exit 1
}

if [[ -z "${OUT_DIR}" ]]; then
  OUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
fi
mkdir -p "${OUT_DIR}"

SCHEMA_FILE="${OUT_DIR}/schema.json"
PROMPT_FILE="${OUT_DIR}/review-prompt.txt"
FINDINGS_FILE="${OUT_DIR}/findings.json"
LAST_MSG_FILE="${OUT_DIR}/last-message.md"

cat >"${SCHEMA_FILE}" <<'JSON'
{
  "type": "object",
  "additionalProperties": false,
  "required": ["findings", "verdict"],
  "properties": {
    "verdict": {
      "type": "string",
      "enum": ["approve", "changes_requested"],
      "description": "approve if no material issues, else changes_requested"
    },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["severity", "file", "line", "summary", "detail", "suggestion"],
        "properties": {
          "severity": { "type": "string", "enum": ["critical", "high", "medium", "low", "nit"] },
          "file": { "type": "string" },
          "line": { "type": ["integer", "null"] },
          "summary": { "type": "string" },
          "detail": { "type": "string" },
          "suggestion": { "type": ["string", "null"] }
        }
      }
    }
  }
}
JSON

cat >"${PROMPT_FILE}" <<PROMPT
You are an adversarial, senior code reviewer for a macOS dotfiles repository.

Review ONLY the changes on the current git branch relative to '${BASE_REF}'.
Start by running: git diff ${BASE_REF}...HEAD
You may also read any file and run read-only analysis (shellcheck, jq, git log).
Do NOT modify, stage, or commit any files. This is review-only.

Judge the changes against these standards, which this repo cares about:
- Bash correctness under 'set -Eeuo pipefail' and stock macOS /bin/bash 3.2
  (empty-array expansion, unbound vars, portable sed/grep).
- Idempotency and graceful degradation when a tool (claude, nb, brew, codex,
  jq) is absent — scripts must skip, not abort a fresh-machine setup.
- Correctness of the unified updater (scripts/dotfiles/update.sh), the Claude
  plugin installer (install/common/agents.sh + agent-plugins.json), the mise
  config change (delta swap, codex provisioning), and staged-setup wiring.
- Security: no secrets, no unsafe eval/word-splitting, safe temp files.
- Consistency with existing repo conventions (lib.sh helpers, task wrappers).

Be precise and skeptical: report only defensible issues with a concrete failure
scenario. Prefer fewer, higher-confidence findings over speculation. If the
changes are sound, return verdict "approve" with an empty findings array.
Emit your result strictly per the provided JSON schema.
PROMPT

# Refuse to review a dirty tree: the sandbox default protects committed work,
# and --danger must never run against uncommitted changes it could clobber.
if [[ -n "$(git -C "${DOTFILES_ROOT}" status --porcelain 2>/dev/null)" ]]; then
  error "working tree is dirty; commit or stash before reviewing (protects uncommitted work)"
  exit 1
fi

# Never carry a previous run's outputs forward: a failed Codex run must not
# leave stale findings behind when --out points at a reused directory.
rm -f "${LAST_MSG_FILE}" "${FINDINGS_FILE}" "${OUT_DIR}/stdout.log"

log "Running Codex review of HEAD vs ${BASE_REF} (output: ${OUT_DIR})"

CODEX_ARGS=(
  exec
  -C "${DOTFILES_ROOT}"
  --output-schema "${SCHEMA_FILE}"
  -o "${LAST_MSG_FILE}"
  --color never
)
if [[ "${DANGER}" == true ]]; then
  warn "running Codex WITHOUT a sandbox (--dangerously-bypass-approvals-and-sandbox)"
  CODEX_ARGS+=(--dangerously-bypass-approvals-and-sandbox)
else
  CODEX_ARGS+=(-s read-only)
fi
[[ -n "${MODEL}" ]] && CODEX_ARGS+=(-m "${MODEL}")

# Codex writes the schema-shaped final message to LAST_MSG_FILE. Redirect stdin
# from /dev/null so a non-TTY invocation never blocks waiting on stdin.
codex_ok=true
if "${CODEX}" "${CODEX_ARGS[@]}" "$(cat "${PROMPT_FILE}")" </dev/null >"${OUT_DIR}/stdout.log" 2>&1; then
  log "Codex review completed"
else
  codex_ok=false
  warn "Codex exited non-zero; inspect ${OUT_DIR}/stdout.log"
fi

# Only publish findings from a successful run with valid schema output.
if [[ "${codex_ok}" == true && -s "${LAST_MSG_FILE}" ]] && jq -e . "${LAST_MSG_FILE}" >/dev/null 2>&1; then
  cp "${LAST_MSG_FILE}" "${FINDINGS_FILE}"
  log "Findings: ${FINDINGS_FILE}"
  jq -r '"verdict: \(.verdict)\nfindings: \(.findings | length)"' "${FINDINGS_FILE}" 2>/dev/null || true
else
  warn "no valid findings produced; see ${OUT_DIR}/stdout.log and ${LAST_MSG_FILE}"
  printf '%s\n' "${OUT_DIR}"
  exit 1
fi

printf '%s\n' "${OUT_DIR}"
