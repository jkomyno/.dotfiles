#!/usr/bin/env bash
# agent-checkpoint.sh — shared, agent-agnostic auto-commit checkpoint.
#
# One implementation, three callers: Claude Code (Stop hook), Codex (notify),
# and pi (agent_end extension). Each caller is a thin adapter; the logic lives
# here so behaviour stays identical across agents.
#
# Policy (see dotfiles decision): auto-COMMIT on every turn, by default, in every
# repo. Committing is local and reversible. Pushing is NOT automatic — it only
# runs when invoked with `push`, only on a feature branch, never on main.
#
# Usage:
#   agent-checkpoint.sh [commit|push] [--agent NAME] [--cwd DIR]
#
# Opt out per-repo with a `.agents-no-checkpoint` file at the repo root,
# or globally/for one call with AGENT_CHECKPOINT=0.
#
# Always exits 0: a checkpoint must never break the agent that called it.

set -uo pipefail

mode="commit"
agent="agent"
cwd=""

case "${1:-}" in
  commit | push)
    mode="$1"
    shift
    ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)
      agent="${2:-agent}"
      shift 2
      ;;
    --cwd)
      cwd="${2:-}"
      shift 2
      ;;
    *) shift ;;
  esac
done

if [ -n "$cwd" ]; then
  cd "$cwd" 2>/dev/null || exit 0
fi

# Must be inside a git work tree; otherwise nothing to do.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
root="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$root" || exit 0

# Opt-outs.
[ "${AGENT_CHECKPOINT:-1}" = "0" ] && exit 0
[ -e ".agents-no-checkpoint" ] && exit 0

# Never touch the tree mid-operation — committing would corrupt an in-flight
# rebase / merge / cherry-pick / revert / bisect.
gitdir="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
for marker in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
  [ -e "$gitdir/$marker" ] && exit 0
done

branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")"

if [ "$mode" = "push" ]; then
  # On-request only. Feature branches with a remote, never the trunk.
  case "$branch" in
    "" | main | master | trunk) exit 0 ;;
  esac
  git push 2>/dev/null ||
    git push --set-upstream origin "$branch" 2>/dev/null ||
    true
  exit 0
fi

# --- commit mode (default) ---

# Nothing staged, unstaged, or untracked → no-op.
[ -z "$(git status --porcelain 2>/dev/null)" ] && exit 0

git add -A 2>/dev/null || exit 0

# Everything might have been ignored; bail if the index is unchanged.
git diff --cached --quiet 2>/dev/null && exit 0

ts="$(date '+%Y-%m-%d %H:%M:%S')"
# --no-verify: checkpoints are throwaway WIP to be squashed; a failing
# pre-commit/lint hook must not silently swallow the safety commit.
git commit --no-verify -q -m "chore(wip): ${agent} checkpoint ${ts}" >/dev/null 2>&1 || true
exit 0
