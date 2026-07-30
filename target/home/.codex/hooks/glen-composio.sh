#!/usr/bin/env bash

set -uo pipefail

readonly allowed_origin="git@github.com:ComposioHQ/composio.git"
readonly glen_bin="${HOME}/.local/share/mise/shims/glen"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
origin="$(git -C "${repo_root}" remote get-url origin 2>/dev/null)" || exit 0
[[ "${origin}" == "${allowed_origin}" ]] || exit 0
[[ -x "${glen_bin}" ]] || exit 0

exec "${glen_bin}" "$@"
