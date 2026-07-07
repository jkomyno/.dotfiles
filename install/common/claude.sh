#!/usr/bin/env bash
# claude.sh — install the Claude Code CLI when it is missing.
#
# codex and pi are provisioned through mise, but Claude Code ships as a
# self-updating native binary under ~/.local/bin/claude with no mise backend, so
# setup.sh otherwise never lays it down — a fresh machine ends up with codex and
# pi but no claude. This runs Anthropic's official installer once, only when
# claude is absent, then gets out of the way (the binary self-updates after).
#
# Idempotent: a machine that already has claude is left untouched. Skippable via
# DOTFILES_SKIP_CLAUDE_INSTALL=1. As a staged step it is optional, so a flaky
# download warns instead of aborting the rest of setup.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

readonly CLAUDE_INSTALL_URL="${CLAUDE_INSTALL_URL:-https://claude.ai/install.sh}"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }

claude_bin() {
	if command -v claude >/dev/null 2>&1; then
		command -v claude
	elif [[ -x "${HOME}/.local/bin/claude" ]]; then
		printf '%s\n' "${HOME}/.local/bin/claude"
	else
		return 1
	fi
}

main() {
	if [[ -n "${DOTFILES_SKIP_CLAUDE_INSTALL:-}" ]]; then
		log "Skipping Claude Code install (DOTFILES_SKIP_CLAUDE_INSTALL is set)"
		return 0
	fi

	local existing
	if existing="$(claude_bin)"; then
		log "Claude Code already installed at ${existing} ($("${existing}" --version 2>/dev/null || echo 'version unknown'))"
		log "It self-updates; no action needed"
		return 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		warn "curl is not available; cannot install Claude Code"
		return 1
	fi

	log "Installing Claude Code via ${CLAUDE_INSTALL_URL}"
	if ! curl -fsSL "${CLAUDE_INSTALL_URL}" | bash; then
		warn "Claude Code installer failed; re-run: mise run install:common:claude"
		return 1
	fi

	local installed
	if installed="$(claude_bin)"; then
		log "Claude Code installed at ${installed}"
		log "Authenticate it with: just auth"
	else
		warn "Installer completed but claude is not on PATH yet; open a new shell, then: just auth"
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
