#!/usr/bin/env bash
# vscode-extensions.sh — install managed VS Code extensions when they are missing.
#
# VS Code itself is a nanobrew cask (install/macos/common/nanobrew-casks.Brewfile),
# but its extensions have no Brewfile or mise backend, so this converges the
# managed list below via `code --install-extension`. VS Code keeps installed
# extensions updated on its own, so this only installs what is absent.
#
# Idempotent: already-installed extensions are left untouched. Skippable via
# DOTFILES_SKIP_VSCODE_EXTENSIONS=1. As a staged step it is optional, so a
# machine without VS Code (for example a headless one) warns instead of
# aborting the rest of setup.
#
# Usage:
#   install/common/vscode-extensions.sh [--check]
#
#   --check  Report missing extensions without installing anything.

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

# Space-separated VS Code extension ids; override with DOTFILES_VSCODE_EXTENSIONS.
# (Not VSCODE_EXTENSIONS: VS Code itself reads that as its extensions
# directory, so exporting a list there breaks the `code` CLI.)
readonly DEFAULT_VSCODE_EXTENSIONS="ms-vscode-remote.remote-ssh"

log() { printf '==> %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }

# The app-bundle fallbacks cover a fresh machine where the cask is installed
# but "Shell Command: Install 'code' command in PATH" has never run.
code_bin() {
	if command -v code >/dev/null 2>&1; then
		command -v code
	elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
		printf '%s\n' "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
	elif [[ -x "${HOME}/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
		printf '%s\n' "${HOME}/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
	else
		return 1
	fi
}

main() {
	local check_only=false
	if [[ "${1:-}" == "--check" ]]; then
		check_only=true
	fi

	if [[ -n "${DOTFILES_SKIP_VSCODE_EXTENSIONS:-}" ]]; then
		log "Skipping VS Code extensions (DOTFILES_SKIP_VSCODE_EXTENSIONS is set)"
		return 0
	fi

	local code_cmd
	if ! code_cmd="$(code_bin)"; then
		warn "VS Code 'code' CLI not found; install the visual-studio-code cask first (just update casks)"
		return 0
	fi

	local installed
	installed="$("${code_cmd}" --list-extensions 2>/dev/null)" || {
		warn "could not list VS Code extensions via ${code_cmd}"
		return 1
	}

	local extension rc=0
	for extension in ${DOTFILES_VSCODE_EXTENSIONS:-${DEFAULT_VSCODE_EXTENSIONS}}; do
		# Extension ids are case-insensitive; --list-extensions prints the
		# publisher's casing, so compare ignoring case.
		if grep -Fxiq "${extension}" <<<"${installed}"; then
			log "VS Code extension ${extension} already installed"
			continue
		fi
		if [[ "${check_only}" == true ]]; then
			log "VS Code extension ${extension} is missing; would install"
			continue
		fi
		log "Installing VS Code extension ${extension}"
		if ! "${code_cmd}" --install-extension "${extension}"; then
			warn "failed to install VS Code extension ${extension}"
			rc=1
		fi
	done
	return "${rc}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
