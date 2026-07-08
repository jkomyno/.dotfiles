#!/usr/bin/env bash
# amp.sh — install the Amp CLI (ampcode.com) when it is missing.
#
# codex and pi are provisioned through mise, but Amp has no practical mise
# backend: every npm release of @sourcegraph/amp carries a -g<hash> suffix that
# mise reads as a prerelease, so `mise ls-remote` returns nothing and a plain
# "latest" spec never resolves (an exact pin installs but never auto-updates and
# trips `mise outdated`). Amp instead ships a self-updating native binary under
# ~/.amp/bin symlinked into ~/.local/bin, exactly like Claude Code, so this runs
# Amp's official installer once, only when amp is absent, then gets out of the
# way (the binary self-updates after; `amp.updates.mode` defaults to "auto").
#
# Idempotent: a machine that already has amp is left untouched. Skippable via
# DOTFILES_SKIP_AMP=1. As a staged step it is optional, so a flaky download
# warns instead of aborting the rest of setup.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

readonly AMP_INSTALL_URL="${AMP_INSTALL_URL:-https://ampcode.com/install.sh}"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }

amp_bin() {
	if command -v amp >/dev/null 2>&1; then
		command -v amp
	elif [[ -x "${HOME}/.local/bin/amp" ]]; then
		printf '%s\n' "${HOME}/.local/bin/amp"
	elif [[ -x "${HOME}/.amp/bin/amp" ]]; then
		printf '%s\n' "${HOME}/.amp/bin/amp"
	else
		return 1
	fi
}

main() {
	if [[ -n "${DOTFILES_SKIP_AMP:-}" ]]; then
		log "Skipping Amp install (DOTFILES_SKIP_AMP is set)"
		return 0
	fi

	local existing
	if existing="$(amp_bin)"; then
		log "Amp already installed at ${existing} ($("${existing}" --version 2>/dev/null || echo 'version unknown'))"
		log "It self-updates; no action needed"
		return 0
	fi

	if ! command -v curl >/dev/null 2>&1; then
		warn "curl is not available; cannot install Amp"
		return 1
	fi

	# ~/.local/bin is already on PATH in these dotfiles; make sure it exists so the
	# installer drops its symlink there instead of editing a managed shell profile.
	mkdir -p "${HOME}/.local/bin"

	log "Installing Amp via ${AMP_INSTALL_URL}"
	if ! curl -fsSL "${AMP_INSTALL_URL}" | bash; then
		warn "Amp installer failed; re-run: mise run install:common:amp"
		return 1
	fi

	local installed
	if installed="$(amp_bin)"; then
		log "Amp installed at ${installed}"
		log "Authenticate it with: amp login"
	else
		warn "Installer completed but amp is not on PATH yet; open a new shell and run: amp login"
	fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
