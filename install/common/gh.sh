#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

readonly DEFAULT_GITHUB_HOST="github.com"
readonly DEFAULT_GH_AUTH_SCOPES="repo,read:org,gist,admin:public_key,admin:ssh_signing_key,write:packages"
readonly DEFAULT_GH_EXTENSIONS="nektos/gh-act"

log() {
	printf '==> %s\n' "$*" >&2
}

activate_mise() {
	if [[ -x "${HOME}/.local/bin/mise" ]]; then
		eval "$("${HOME}/.local/bin/mise" activate bash)"
	elif command -v mise >/dev/null 2>&1; then
		eval "$(mise activate bash)"
	fi
}

require_gh() {
	if command -v gh >/dev/null 2>&1; then
		return 0
	fi

	log "Skipping GitHub CLI setup because gh is not available yet"
	return 1
}

# Only touch host-scoped settings, which live in the unmanaged hosts.yml.
# `gh config set` without --host rewrites ~/.config/gh/config.yml (dropping
# comments and ordering), which would fight with the managed config file.
configure_gh() {
	gh config set git_protocol ssh --host "${DEFAULT_GITHUB_HOST}" >/dev/null
}

is_authenticated() {
	gh auth status --hostname "${DEFAULT_GITHUB_HOST}" >/dev/null 2>&1
}

print_login_hint() {
	local scopes="${GH_AUTH_SCOPES:-${DEFAULT_GH_AUTH_SCOPES}}"

	log "GitHub CLI is not authenticated for ${DEFAULT_GITHUB_HOST}"
	log "Run: gh auth login --hostname ${DEFAULT_GITHUB_HOST} --git-protocol ssh --web --scopes \"${scopes}\""
}

extension_installed() {
	local repository="$1"

	gh extension list | awk '{ print $3 }' | grep -Fxq "${repository}"
}

install_extension() {
	local repository="$1"

	if extension_installed "${repository}"; then
		log "gh extension ${repository} already installed"
		return 0
	fi

	log "Installing gh extension ${repository}"
	if ! gh extension install "${repository}"; then
		log "Failed to install gh extension ${repository}"
	fi
}

# Mirrors install/common/git-signing.sh so the key uploaded here is the one
# Git is configured to sign with.
detect_signing_key() {
	local candidate

	for candidate in "${GIT_SSH_SIGNING_KEY:-}" "${HOME}/.ssh/id_ed25519.pub" "${HOME}/.ssh/id_rsa.pub"; do
		[[ -n "${candidate}" ]] || continue
		[[ "${candidate}" == *.pub ]] || candidate="${candidate}.pub"

		if [[ -f "${candidate}" ]]; then
			printf '%s\n' "${candidate}"
			return 0
		fi
	done

	return 1
}

upload_signing_key() {
	local key_path key_material

	if ! key_path="$(detect_signing_key)"; then
		log "No SSH public key found; skipping GitHub signing key upload"
		return 0
	fi

	key_material="$(awk '{ print $2 }' "${key_path}")"

	if gh ssh-key list 2>/dev/null | grep -Fq "${key_material}"; then
		log "SSH key ${key_path} already registered on GitHub"
		return 0
	fi

	log "Uploading ${key_path} to GitHub as a signing key"
	if ! gh ssh-key add "${key_path}" --type signing --title "$(hostname -s) signing key"; then
		log "Failed to upload signing key; run: gh ssh-key add ${key_path} --type signing"
	fi
}

install_extensions() {
	local extensions_string="${GH_EXTENSIONS:-${DEFAULT_GH_EXTENSIONS}}"
	local extension

	for extension in ${extensions_string}; do
		install_extension "${extension}"
	done
}

main() {
	activate_mise
	require_gh || return 0
	configure_gh

	if ! is_authenticated; then
		print_login_hint
		return 0
	fi

	log "GitHub CLI authenticated for ${DEFAULT_GITHUB_HOST}"
	upload_signing_key
	install_extensions
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
