#!/usr/bin/env bash
# sync.sh — Deterministic portion of the vendored skills sync.
#
# Reads manifest.json (skill name -> upstream repo + path), shallow-clones each
# unique upstream once, and compares every vendored skill in the dotfiles source
# tree against upstream after applying our patch files.
#
# Run this against the dotfiles SOURCE checkout (target/home/.agents/skills), not
# the deployed ~/.agents/skills, so accepted changes land in git.
#
# Usage:
#   bash sync.sh [--skills-dir <dir>] [--keep-upstream]
#
# Output: structured report on stdout for the agent to parse.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$(dirname "$SKILL_ROOT")"
MANIFEST="$SKILL_ROOT/manifest.json"
PATCHES_DIR="$SKILL_ROOT/patches"
EXCLUDED_FILE="$PATCHES_DIR/excluded.txt"
KEEP_UPSTREAM=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir)
      [[ $# -ge 2 ]] || { echo "ERROR: --skills-dir needs a value" >&2; exit 2; }
      SKILLS_DIR="$2"
      shift 2
      ;;
    --keep-upstream)
      KEEP_UPSTREAM=1
      shift
      ;;
    -h|--help)
      echo "Usage: sync.sh [--skills-dir <dir>] [--keep-upstream]"
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

command -v jq >/dev/null || { echo "ERROR: jq is required" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "ERROR: manifest not found: $MANIFEST" >&2; exit 1; }

if [[ "$KEEP_UPSTREAM" -eq 1 ]]; then
  WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/skills-sync.XXXXXX")
else
  WORK_DIR=$(mktemp -d)
fi
cleanup() { [[ "$KEEP_UPSTREAM" -eq 1 ]] || rm -rf "$WORK_DIR"; }
trap cleanup EXIT

repo_slug() {
  printf '%s' "$1" | sed -E 's#^https?://[^/]+/##; s#\.git$##; s#[^A-Za-z0-9._-]#__#g'
}

is_excluded() {
  [[ -f "$EXCLUDED_FILE" ]] && grep -qxF "$1" "$EXCLUDED_FILE" 2>/dev/null
}

our_skill_dir() {
  local name=$1
  if [[ -d "$SKILLS_DIR/$name" ]]; then
    printf '%s' "$SKILLS_DIR/$name"
  fi
}

upstream_files() {
  local root=$1
  local include_json=$2
  local include_path

  if [[ "$(jq 'length' <<<"$include_json")" -gt 0 ]]; then
    while IFS= read -r include_path; do
      if [[ -d "$root/$include_path" ]]; then
        command find "$root/$include_path" -type f ! -path '*/.git/*'
      elif [[ -f "$root/$include_path" ]]; then
        printf '%s\n' "$root/$include_path"
      fi
    done < <(jq -r '.[]' <<<"$include_json")
  else
    command find "$root" -type f ! -path '*/.git/*'
  fi | sort -u
}

# --- Clone each unique upstream once ---
echo "STATUS: cloning upstreams"
mkdir -p "$WORK_DIR/repos"
while IFS= read -r repo; do
  slug=$(repo_slug "$repo")
  [[ -d "$WORK_DIR/repos/$slug" ]] && continue
  if ! git clone --depth 1 --quiet "$repo" "$WORK_DIR/repos/$slug" 2>/dev/null; then
    echo "ERROR: failed to clone $repo"
    exit 1
  fi
done < <(jq -r '.skills[].repo' "$MANIFEST" | sort -u)
echo "STATUS: clones complete"

# --- Section 1: Upstream changes to vendored skills ---
echo ""
echo "=== UPSTREAM_CHANGES ==="
while IFS=$'\t' read -r name repo path include_json; do
  slug=$(repo_slug "$repo")
  upstream_path="$WORK_DIR/repos/$slug/$path"
  our_path=$(our_skill_dir "$name")

  if [[ ! -d "$upstream_path" ]]; then
    echo "MISSING_UPSTREAM: $name | $repo | $path"
    continue
  fi
  missing_include=0
  while IFS= read -r include_path; do
    if [[ ! -e "$upstream_path/$include_path" ]]; then
      echo "MISSING_UPSTREAM: $name | $repo | $path/$include_path"
      missing_include=1
    fi
  done < <(jq -r '.[]' <<<"$include_json")
  [[ "$missing_include" -eq 0 ]] || continue
  if [[ -z "$our_path" ]]; then
    echo "MISSING_LOCAL: $name (in manifest, not vendored)"
    continue
  fi

  changed_files=()
  while IFS= read -r upstream_file; do
    rel_path="${upstream_file#"$upstream_path"/}"
    our_file="$our_path/$rel_path"

    if [[ ! -f "$our_file" ]]; then
      changed_files+=("$rel_path (new file upstream)")
      continue
    fi

    expected_tmp="$WORK_DIR/expected"
    cp "$upstream_file" "$expected_tmp"

    patch_file="$PATCHES_DIR/${name}__${rel_path//\//__}.patch"
    patch_status="none"
    if [[ -f "$patch_file" ]]; then
      patch_status="has patch"
      if ! patch --quiet --forward "$expected_tmp" "$patch_file" 2>/dev/null; then
        changed_files+=("$rel_path (patch conflict)")
        rm -f "$expected_tmp"
        continue
      fi
    fi

    if ! diff -q "$expected_tmp" "$our_file" >/dev/null 2>&1; then
      if [[ "$patch_status" == "has patch" ]]; then
        changed_files+=("$rel_path (upstream changed, has patch)")
      else
        changed_files+=("$rel_path (changed, no patch)")
      fi
    fi
    rm -f "$expected_tmp"
  done < <(upstream_files "$upstream_path" "$include_json")

  while IFS= read -r our_file; do
    rel_path="${our_file#"$our_path"/}"
    [[ -f "$upstream_path/$rel_path" ]] || changed_files+=("$rel_path (removed upstream)")
  done < <(command find "$our_path" -type f | sort)

  if [[ ${#changed_files[@]} -gt 0 ]]; then
    echo "CHANGED: $name"
    for f in "${changed_files[@]}"; do
      echo "  - $f"
    done
  fi
done < <(jq -r '.skills | to_entries[] | [.key, .value.repo, .value.path, ((.value.include // []) | tojson)] | @tsv' "$MANIFEST")

# --- Section 2: Other skills in repos we already track ---
echo ""
echo "=== NEW_SKILLS ==="
while IFS= read -r repo; do
  slug=$(repo_slug "$repo")
  repo_root="$WORK_DIR/repos/$slug"
  while IFS= read -r skill_md; do
    skill_dir=$(dirname "$skill_md")
    skill_name=$(basename "$skill_dir")
    if [[ "$skill_dir" == "$repo_root" ]]; then
      rel_dir="."
    else
      rel_dir="${skill_dir#"$repo_root/"}"
    fi
    # Skip if any manifest entry for this repo already points at this path.
    tracked=$(jq -r --arg repo "$repo" --arg path "$rel_dir" \
      '.skills | to_entries[] | select(.value.repo == $repo and .value.path == $path) | .key' "$MANIFEST")
    [[ -n "$tracked" ]] && continue
    is_excluded "$skill_name" && continue
    desc=$(grep -m1 '^description:' "$skill_md" 2>/dev/null | sed 's/^description: *//' | cut -c1-120 || true)
    echo "NEW: $skill_name | repo=$repo | path=$rel_dir | ${desc:-(no description)}"
  done < <(command find "$WORK_DIR/repos/$slug" -name SKILL.md ! -path '*/node_modules/*' ! -path '*/.git/*' | sort)
done < <(jq -r '.skills[].repo' "$MANIFEST" | sort -u)

# --- Section 3: Host-specific wording that needs local patches ---
echo ""
echo "=== UNPATCHED_PATTERNS ==="
PATTERNS='Claude Code|CLAUDE\.md|sub.agent|subagent|Agent tool|spawn.*agent|subagent_type'
while IFS=$'\t' read -r name repo path; do
  our_path=$(our_skill_dir "$name")
  [[ -n "$our_path" ]] || continue

  while IFS= read -r file; do
    rel_path="${file#"$our_path"/}"
    patch_file="$PATCHES_DIR/${name}__${rel_path//\//__}.patch"
    [[ -f "$patch_file" ]] && continue

    matches=$(grep -niE "$PATTERNS" "$file" 2>/dev/null || true)
    if [[ -n "$matches" ]]; then
      echo "UNPATCHED: $name/$rel_path"
      echo "$matches" | while IFS= read -r line; do
        echo "  $line"
      done
    fi
  done < <(command find "$our_path" \( -name "*.md" -o -name "*.sh" \) -type f | sort)
done < <(jq -r '.skills | to_entries[] | [.key, .value.repo, .value.path] | @tsv' "$MANIFEST")

# --- Section 4: Upstream clones for the agent to read ---
echo ""
echo "=== UPSTREAM_DIRS ==="
while IFS= read -r repo; do
  echo "$repo -> $WORK_DIR/repos/$(repo_slug "$repo")"
done < <(jq -r '.skills[].repo' "$MANIFEST" | sort -u)
if [[ "$KEEP_UPSTREAM" -eq 1 ]]; then
  echo "STATUS: upstream clones retained"
else
  echo "STATUS: upstream clones removed on exit; use --keep-upstream to inspect them"
fi

echo ""
echo "STATUS: sync analysis complete"
