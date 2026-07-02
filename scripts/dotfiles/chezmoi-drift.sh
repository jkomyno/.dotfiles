#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/chezmoi-drift.sh <status|diff>

Compare deployed-home drift only when this checkout is the active chezmoi
source. Set DOTFILES_FORCE_CHEZMOI_DRIFT=1 to force a comparison against the
current HOME anyway.
USAGE
}

normalized_path() {
  local path="$1"
  if [[ -d "${path}" ]]; then
    cd -- "${path}" && pwd -P
  else
    printf '%s\n' "${path}"
  fi
}

main() {
  local command_name="${1:-}"
  case "${command_name}" in
    status | diff)
      ;;
    -h | --help)
      usage
      return 0
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac

  local chezmoi_cmd
  if ! chezmoi_cmd="$(chezmoi_bin)"; then
    warn "chezmoi is missing; skipping deployed-home ${command_name}"
    return 0
  fi

  local active_source expected_source
  active_source="$("${chezmoi_cmd}" source-path 2>/dev/null || true)"
  expected_source="${DOTFILES_ROOT}/home"

  active_source="$(normalized_path "${active_source}" || true)"
  expected_source="$(normalized_path "${expected_source}")"

  if [[ "${active_source}" != "${expected_source}" && -z "${DOTFILES_FORCE_CHEZMOI_DRIFT:-}" ]]; then
    warn "skipping chezmoi ${command_name}: active source is ${active_source:-unknown}, not ${expected_source}"
    warn "set DOTFILES_FORCE_CHEZMOI_DRIFT=1 to compare this checkout against the current HOME anyway"
    return 0
  fi

  if [[ "${active_source}" == "${expected_source}" ]]; then
    "${chezmoi_cmd}" "${command_name}"
  else
    run_chezmoi_source "${command_name}"
  fi
}

main "$@"
