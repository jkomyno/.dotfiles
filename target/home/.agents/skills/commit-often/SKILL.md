---
name: commit-often
description: >-
  Commit completed units of work as you go instead of batching everything
  into one commit at the end. Use during any coding session that will
  produce more than one logical change: after each green test run, when a
  logical unit is complete, or before starting a risky refactor. Also
  applies when the user says "commit often", "checkpoint", or "commit as
  you go".
---

# Commit Often

Working code that exists only in the working tree is one bad command away
from gone. Commit at every logical unit so each step is small, reviewable,
and individually revertible.

## When to commit

- A logical unit is complete — one behavior added, one bug fixed, one rename
  done — and the build is green.
- Before starting anything risky: a cross-cutting refactor, a dependency
  bump, a migration.
- Before switching focus to a different part of the task.

If several files of churn have accumulated without a commit, stop and split
out what is already complete.

## How to commit

- Stage files explicitly (`git add <file> ...`), never `git add .` or
  `git add -A`. Listing files catches strays before they land.
- Conventional Commits style, imperative mood: `feat:`, `fix:`,
  `refactor:`, `chore:`, `test:`, `docs:`.
- The message explains why; the diff already shows what.
- Never add AI attribution: no `Co-Authored-By`, no "Generated with"
  trailers.
- Don't commit broken states to "save progress". If the build is red,
  either finish the unit or stash.

## Splitting accumulated work

When several units have piled up unstaged, don't flatten them into one
commit. Stage and commit them separately (`git add -p` for files that mix
units), in dependency order, each leaving the build green.
