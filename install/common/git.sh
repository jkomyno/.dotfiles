#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
	set -x
fi

log() {
	printf '==> %s\n' "$*" >&2
}

next_backup_path() {
	local target="$1"
	local backup="${target}.pre-xdg-git"
	local index=1

	while [[ -e "${backup}" || -L "${backup}" ]]; do
		backup="${target}.pre-xdg-git.${index}"
		index=$((index + 1))
	done

	printf '%s\n' "${backup}"
}

migrate_legacy_file() {
	local legacy_path="$1"
	local replacement_path="$2"

	[[ -e "${legacy_path}" || -L "${legacy_path}" ]] || return 0
	[[ -e "${replacement_path}" || -L "${replacement_path}" ]] || return 0

	if cmp -s "${legacy_path}" "${replacement_path}"; then
		log "Removing legacy ${legacy_path}"
		rm -f "${legacy_path}"
		return 0
	fi

	local backup_path
	backup_path="$(next_backup_path "${legacy_path}")"
	log "Moving legacy ${legacy_path} to ${backup_path}"
	mv "${legacy_path}" "${backup_path}"
}

main() {
	[[ -e "${HOME}/.config/git/config" ]] || return 0

	migrate_legacy_file "${HOME}/.gitconfig" "${HOME}/.config/git/config"
	migrate_legacy_file "${HOME}/.gitconfig-composio" "${HOME}/.config/git/config-composio"
	migrate_legacy_file "${HOME}/.gitignore" "${HOME}/.config/git/ignore"
	migrate_legacy_file "${HOME}/.gitignore_global" "${HOME}/.config/git/ignore"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
