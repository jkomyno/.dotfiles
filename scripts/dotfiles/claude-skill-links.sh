#!/usr/bin/env bash
# Reconcile the shared agent skill view, Claude links and profile-owned settings.
set -Eeuo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source "${script_dir}/lib.sh"
profile_resolve
exec python3 -Bs "${script_dir}/agent-profile.py" "$@"
