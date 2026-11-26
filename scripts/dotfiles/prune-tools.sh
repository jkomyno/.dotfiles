#!/usr/bin/env bash
# Preview superseded managed tools; pass --apply to remove them.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

args=(--dry-run)
case "${1:---dry-run}" in
  --dry-run) ;;
  --apply) args=(--yes) ;;
  -h | --help)
    printf 'Usage: just prune-tools [--dry-run|--apply]\n'
    exit 0
    ;;
  *) error "expected --dry-run or --apply"; exit 2 ;;
esac
[[ $# -le 1 ]] || { error "too many arguments"; exit 2; }

# Scope collection to tools we declare. Ad hoc installations stay installed.
# mise also preserves versions selected by tracked projects and running processes.
profile_resolve
profile_report
configured="$(run_source_mise ls --current --json | python3 -c 'import json, sys; print("\n".join(sorted(json.load(sys.stdin))))')"
tools=()
while IFS= read -r tool; do [[ -z "${tool}" ]] || tools+=("${tool}"); done <<<"${configured}"
[[ ${#tools[@]} -gt 0 ]] || { error "no managed tool declarations found"; exit 1; }
run_source_mise prune --tools ${args[@]+"${args[@]}"} "${tools[@]}"
