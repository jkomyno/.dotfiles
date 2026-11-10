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
tools=()
while IFS= read -r tool; do tools+=("${tool}"); done < <(
  python3 - "${DOTFILES_MISE_DIR}" <<'PY'
import pathlib
import sys
import tomllib

root = pathlib.Path(sys.argv[1])
files = [root / "config.toml"]
if sys.platform.startswith("linux"):
    files.append(root / "config.linux.toml")
names = set()
for path in files:
    names.update(tomllib.loads(path.read_text()).get("tools", {}))
print("\n".join(sorted(names)))
PY
)
[[ ${#tools[@]} -gt 0 ]] || { error "no managed tool declarations found"; exit 1; }
"$(mise_bin)" prune --tools ${args[@]+"${args[@]}"} "${tools[@]}"
