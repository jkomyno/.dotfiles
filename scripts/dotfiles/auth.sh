#!/usr/bin/env bash
# auth.sh — bring the coding-agent CLIs to an authenticated state.
#
# Dotfiles setup deliberately never stores CLI credentials: gh keeps its token
# in the system keyring, while codex and claude use browser OAuth tied to a
# ChatGPT / Anthropic subscription. None of that can (or should) live in a git
# checkout, so authentication is the one manual step left after `setup.sh`.
#
# This script is that step. It reports what is already authenticated and drives
# the interactive login flow for whatever is not. It is idempotent: a tool that
# is already logged in is left untouched.
#
# Self-healing install: most CLIs come from mise, but Claude Code has no mise
# backend — setup lays it down through install/common/claude.sh, an optional
# step whose flaky download or skip can leave a fresh machine without claude. So
# when a tool that ships its own installer is missing here, auth runs that
# installer first rather than dead-ending on a skip, then logs in as usual.
#
# SSH-aware: when run inside an SSH session (SSH_CONNECTION / SSH_TTY /
# SSH_CLIENT), login flows steer clear of browser-callback grants that would
# need port forwarding to complete — the OAuth localhost callback lands on the
# local machine, not the remote one running the CLI. codex switches to
# device-code auth (`--device-auth`). claude has no such flag, but its login
# already falls back to a paste-a-code prompt when the localhost callback is
# unreachable, which is exactly what SSH needs. gh uses a device code regardless.
#
# Modes:
#   (default)  Log in to every supported tool that is not yet authenticated.
#   --check    Report status only; never launch a login flow. Exit non-zero if
#              any installed tool is unauthenticated (so `just auth-check` and CI
#              can gate on it).

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

readonly GITHUB_HOST="github.com"
readonly GH_AUTH_SCOPES="${GH_AUTH_SCOPES:-repo,read:org,gist,admin:public_key,admin:ssh_signing_key,write:packages}"

MODE="login"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | --plan) MODE="check" ;;
    -h | --help)
      grep -E '^# ' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      error "unknown argument: $1"
      exit 2
      ;;
  esac
  shift
done

# Detect an SSH session so login flows avoid browser-callback grants that would
# need port forwarding. Over SSH the OAuth localhost callback binds on the remote
# host but the redirect fires against the operator's local browser, so the two
# never meet; code-based flows sidestep the mismatch entirely.
is_ssh_session() {
  [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" || -n "${SSH_CLIENT:-}" ]]
}

# The CLIs are provisioned through mise, so their shims are only on PATH once
# mise is active. Mirror install/common/agents.sh so this runs standalone too.
activate_mise() {
  if [[ -x "${HOME}/.local/bin/mise" ]]; then
    eval "$("${HOME}/.local/bin/mise" activate bash)" 2>/dev/null || true
  elif have mise; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
}

# Each tool exposes a status probe (exit 0 == authenticated) and a login verb.
gh_status() { gh auth status --hostname "${GITHUB_HOST}" >/dev/null 2>&1; }
gh_login() {
  gh auth login --hostname "${GITHUB_HOST}" --git-protocol ssh --web --scopes "${GH_AUTH_SCOPES}"
}

codex_status() { codex login status >/dev/null 2>&1; }
codex_login() {
  # Plain `codex login` serves an OAuth callback on localhost:1455; over SSH that
  # port lives on the wrong host, so switch to device-code auth instead.
  if is_ssh_session; then
    codex login --device-auth
  else
    codex login
  fi
}

# `claude auth status` prints JSON and exits 0 even when signed out, so key off
# the loggedIn flag rather than the exit code.
claude_status() { claude auth status 2>/dev/null | grep -q '"loggedIn": *true'; }
claude_login() {
  # Claude Code exposes no device-auth flag: `claude auth login` uses a
  # localhost:54545 callback and falls back to a paste-a-code prompt when that
  # callback is unreachable — the SSH case. Flag the expectation, then run the
  # normal flow; no port forwarding required.
  if is_ssh_session; then
    info "claude: open the printed URL in your local browser, then paste the code back here (no port forwarding needed)"
  fi
  claude auth login
}

# Claude Code ships no mise backend; setup installs it through this same script.
# converge() calls `<tool>_install` when a tool is missing, so lay claude down
# here — the installer drops it in ~/.local/bin, already on PATH from
# activate_mise. Only claude defines an installer; gh and codex come from setup.
claude_install() {
  bash "${DOTFILES_ROOT}/install/common/claude.sh"
}

UNAUTHENTICATED=0

# converge <tool> — probe one tool and, in login mode, run its flow if needed.
converge() {
  local tool="$1"

  if ! have "${tool}"; then
    # A tool with its own installer (only claude) can be absent when setup's
    # optional install step was skipped or its download failed. Self-heal in
    # login mode so `just auth` installs it instead of dead-ending; check mode
    # only reports. `hash -r` forgets the negative lookup so the freshly linked
    # binary is visible without a new shell.
    if [[ "${MODE}" == "login" ]] && declare -F "${tool}_install" >/dev/null; then
      log "${tool}: not installed; running its installer"
      "${tool}_install" || warn "${tool}: installer did not complete"
      hash -r 2>/dev/null || true
    fi

    if ! have "${tool}"; then
      info "${tool}: not installed yet; skipping"
      return 0
    fi
  fi

  if "${tool}_status"; then
    log "${tool}: authenticated"
    return 0
  fi

  UNAUTHENTICATED=$((UNAUTHENTICATED + 1))

  if [[ "${MODE}" == "check" ]]; then
    warn "${tool}: NOT authenticated (run: just auth)"
    return 0
  fi

  if [[ ! -t 0 ]]; then
    warn "${tool}: NOT authenticated and no terminal to run the login flow"
    warn "${tool}: run \`just auth\` from an interactive shell"
    return 0
  fi

  log "${tool}: launching login flow"
  if "${tool}_login" && "${tool}_status"; then
    log "${tool}: authenticated"
    UNAUTHENTICATED=$((UNAUTHENTICATED - 1))
  else
    warn "${tool}: login did not complete; re-run \`just auth\`"
  fi
}

main() {
  activate_mise

  converge gh
  converge codex
  converge claude

  if [[ "${MODE}" == "check" && "${UNAUTHENTICATED}" -gt 0 ]]; then
    return 1
  fi
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
