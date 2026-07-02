#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

readonly DEFAULT_SSH_KEY_COMMENT="12381818+jkomyno@users.noreply.github.com"

log() {
	printf '==> %s\n' "$*" >&2
}

# Mirrors install/common/git-signing.sh so a machine that already has a usable
# keypair is left untouched.
existing_keypair() {
	local candidate

	for candidate in "${GIT_SSH_SIGNING_KEY:-}" "${HOME}/.ssh/id_ed25519" "${HOME}/.ssh/id_rsa"; do
		[[ -n "${candidate}" ]] || continue
		candidate="${candidate%.pub}"

		if [[ -f "${candidate}" && -f "${candidate}.pub" ]]; then
			printf '%s\n' "${candidate}"
			return 0
		fi
	done

	return 1
}

main() {
	if [[ -n "${DOTFILES_SKIP_SSH_KEYGEN:-}" ]]; then
		log "Skipping SSH key generation (DOTFILES_SKIP_SSH_KEYGEN is set)"
		return 0
	fi

	local key_path
	if key_path="$(existing_keypair)"; then
		log "SSH key already exists at ${key_path}"
		return 0
	fi

	key_path="${HOME}/.ssh/id_ed25519"
	log "Generating ${key_path}"
	mkdir -p "${HOME}/.ssh"
	chmod 700 "${HOME}/.ssh"
	ssh-keygen -t ed25519 -C "${SSH_KEY_COMMENT:-${DEFAULT_SSH_KEY_COMMENT}}" -f "${key_path}" -N ""

	log "New SSH public key:"
	cat "${key_path}.pub" >&2
	log "Add it to GitHub for authentication: gh ssh-key add ${key_path}.pub --title \"$(hostname -s)\""
	log "The signing key is uploaded automatically once gh is authenticated"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
