---
name: pr-janitor
description: Keep a pull request green and mergeable. Use for "fix CI", review feedback, CodeRabbit, failing-check links, or "babysit this PR"; stop at merge-ready or a human decision.
---

# PR Janitor

Given a PR, or the PR linked to the current branch, iterate until it is green
and mergeable or a stop condition applies.

## Operating Loop

1. Read the exact PR head, base, checks, reviews, and unresolved comments. Treat
   bot comments as review input, not automatic truth.
2. Classify failures before editing. Reproduce source failures with the
   repository's fast local checks; leave e2e coverage to CI unless repository
   guidance says otherwise.
3. Fix one concern per Conventional Commit. Do not add AI attribution. Draft
   review replies by default; post them only when the user already authorized
   public comments.
4. Push only to the PR's linked branch. Never push to the default branch or
   force-push over commits you do not own.
5. Re-read the remote head, comments, and checks after every push. Repeat until
   green or blocked.

## Stop Conditions

- A comment requires a product, design, security, release, or compatibility
  decision from the user.
- A failure requires credentials, infrastructure access, or an external state
  change that is unavailable.
- The PR is green and mergeable under its actual review and branch rules.

## Report

Summarize commits pushed, comments resolved, current checks, review state, and
the remaining user action. End with the standard `What's next:` handoff line.
