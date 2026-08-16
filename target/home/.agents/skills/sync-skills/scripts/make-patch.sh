#!/usr/bin/env bash
# make-patch.sh — Record a local modification to a vendored skill file as a
# patch with stable labels, so future syncs can re-apply it on top of upstream.
#
# Usage:
#   bash make-patch.sh <skill_name> <rel_path> <upstream_file> <our_file>
#
# Writes patches/<skill_name>__<rel_path with / replaced by __>.patch

set -euo pipefail

[[ $# -eq 4 ]] || { echo "Usage: make-patch.sh <skill_name> <rel_path> <upstream_file> <our_file>" >&2; exit 2; }

NAME="$1"
REL_PATH="$2"
UPSTREAM_FILE="$3"
OUR_FILE="$4"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$(dirname "$SCRIPT_DIR")/patches"

[[ -f "$UPSTREAM_FILE" ]] || { echo "ERROR: upstream file not found: $UPSTREAM_FILE" >&2; exit 1; }
[[ -f "$OUR_FILE" ]] || { echo "ERROR: our file not found: $OUR_FILE" >&2; exit 1; }

PATCH_FILE="$PATCHES_DIR/${NAME}__${REL_PATH//\//__}.patch"
mkdir -p "$PATCHES_DIR"

if diff -u --label "upstream/$NAME/$REL_PATH" --label "ours/$NAME/$REL_PATH" \
    "$UPSTREAM_FILE" "$OUR_FILE" > "$PATCH_FILE"; then
  rm -f "$PATCH_FILE"
  echo "STATUS: no difference, no patch written"
else
  # Unified diffs mark blank context lines with one space. GNU and BSD patch
  # accept those lines without the marker, which keeps git whitespace checks
  # useful for vendored patch files.
  NORMALIZED_PATCH="${PATCH_FILE}.normalized"
  sed 's/^ $//' "$PATCH_FILE" > "$NORMALIZED_PATCH"
  mv "$NORMALIZED_PATCH" "$PATCH_FILE"
  echo "WROTE: $PATCH_FILE"
fi
