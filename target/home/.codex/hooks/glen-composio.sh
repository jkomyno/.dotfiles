#!/usr/bin/env bash

set -uo pipefail

readonly allowed_origin="git@github.com:ComposioHQ/composio.git"
readonly mise_bin="${HOME}/.local/bin/mise"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
origin="$(git -C "${repo_root}" remote get-url origin 2>/dev/null)" || exit 0
[[ "${origin}" == "${allowed_origin}" ]] || exit 0
[[ -x "${mise_bin}" ]] || exit 0

exec "${mise_bin}" exec -- glen "$@"
