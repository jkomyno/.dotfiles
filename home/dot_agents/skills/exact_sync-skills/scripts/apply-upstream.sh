#!/usr/bin/env bash
# apply-upstream.sh — Replace a vendored skill with its upstream copy, then
# re-apply any local patches from the patches/ directory and configured
# frontmatter overrides.
#
# Usage:
#   bash apply-upstream.sh <skill_name> <upstream_skill_dir> [--skills-dir <dir>]

set -euo pipefail

[[ $# -ge 2 ]] || { echo "Usage: apply-upstream.sh <skill_name> <upstream_skill_dir> [--skills-dir <dir>]" >&2; exit 2; }

NAME="$1"
UPSTREAM_DIR="$2"
shift 2

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$(dirname "$SKILL_ROOT")"
PATCHES_DIR="$SKILL_ROOT/patches"
OVERRIDES_SCRIPT="$SCRIPT_DIR/apply-frontmatter-overrides.py"

if [[ "${1:-}" == "--skills-dir" ]]; then
  [[ $# -ge 2 ]] || { echo "ERROR: --skills-dir needs a value" >&2; exit 2; }
  SKILLS_DIR="$2"
fi

[[ -d "$UPSTREAM_DIR" ]] || { echo "ERROR: upstream dir not found: $UPSTREAM_DIR" >&2; exit 1; }

if [[ -d "$SKILLS_DIR/exact_$NAME" ]]; then
  OUR_DIR="$SKILLS_DIR/exact_$NAME"
elif [[ -d "$SKILLS_DIR/$NAME" ]]; then
  OUR_DIR="$SKILLS_DIR/$NAME"
else
  OUR_DIR="$SKILLS_DIR/exact_$NAME"
  echo "STATUS: installing new skill into $OUR_DIR"
fi

rm -rf "$OUR_DIR"
mkdir -p "$OUR_DIR"
cp -R "$UPSTREAM_DIR/." "$OUR_DIR/"
echo "STATUS: copied upstream into $OUR_DIR"

shopt -s nullglob
for patch_file in "$PATCHES_DIR/${NAME}__"*.patch; do
  rel_path=$(basename "$patch_file" .patch)
  rel_path="${rel_path#"${NAME}__"}"
  rel_path="${rel_path//__//}"
  target="$OUR_DIR/$rel_path"
  if patch --quiet --forward "$target" "$patch_file"; then
    echo "PATCHED: $rel_path"
  else
    echo "PATCH_CONFLICT: $rel_path ($patch_file)"
  fi
done

if [[ -f "$OUR_DIR/SKILL.md" && -f "$OVERRIDES_SCRIPT" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 "$OVERRIDES_SCRIPT" "$NAME" "$OUR_DIR/SKILL.md" "$PATCHES_DIR"
  elif [[ -f "$PATCHES_DIR/local-overrides.json" ]] && grep -q "\"$NAME\"" "$PATCHES_DIR/local-overrides.json"; then
    echo "PATCH_CONFLICT: SKILL.md frontmatter overrides need python3"
  fi
fi

echo "STATUS: apply complete for $NAME"
