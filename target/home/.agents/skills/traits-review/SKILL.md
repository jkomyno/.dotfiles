---
name: traits-review
description: >-
  Check work against history-derived coding preferences after a substantive code
  change, during code review, or when asked to apply traits. Uses the current
  coding-agent session; no Traits MCP server or separate model API is needed.
---

# Traits review

Review with the model and tools already serving this session. Do not install a
model provider, call a separate API, or start another agent for this check.
These are Traits-format preferences; this workflow does not implement the
upstream decision model or its probability scores.

## Scope and definitions

Use the current task's changed files or the user's named review scope. Read
the diff and enough surrounding code to establish the relevant contracts.
Do not turn a local change into a repository-wide audit.

Read applicable trait definitions from the project's `.agents/traits/*.md`
and the managed `~/.agents/trait-seeds/*.md` library. Resolve the latter through
`../../trait-seeds` relative to this skill's real directory if needed. A project
trait with the same name replaces that seed for the review. Apply repository
instructions and actual contracts when judging applicability. Report a missing
or malformed definition instead of silently claiming it was checked.

Use each trait's `subject`, `requirement`, and `applicability` as the assessment
criterion. Its purpose and Markdown body explain context; do not invent extra
obligations from them. Omit irrelevant traits. Compatibility status, the
original failure, or benchmark results may require context beyond source code.

## Assessment

For each relevant trait, decide whether the selected work is compliant,
violates it, is outside its applicability, or is inconclusive. Confirm a
violation against the surrounding code and a concrete failure or maintenance
problem. Missing context is not proof of a violation.

Check at a completed logical checkpoint, rather than after every edit. When
fixes are already authorized, make the smallest correction for confirmed
violations and run the relevant existing checks. A review-only request remains
read-only. Do not change behavior, broaden scope, remove compatibility, or
weaken tests merely to satisfy a preference.

Report confirmed findings with the trait name, a source location, and a short
explanation. State material uncertainty and which scope was reviewed; otherwise
keep the result brief. Never invent numerical confidence or claim independent
review, repository-wide compliance, or a successful upstream `check_traits`
call from this self-review.

## Learning

A correction applies immediately to the current task. Persist new or changed
traits only when the user requests learning or approves the concrete update.
Preserve scope and exceptions, compare existing definitions, and keep raw
session evidence outside the repository. A quoted assistant recommendation or
coordinator prompt is not itself a user preference.
