---
name: ship-it
description: Audit a repository's last mile and drive it to shipped. Use when the user says "ship it", "what's left to release", "finish the release", or "promote the rc", or asks why something is not published, tagged, or merged. Finds unmerged PRs, unpublished changesets, missing tags, unpromoted dist-tags, and release-ready repositories, then executes authorized safe steps and identifies the remaining human gates.
---

# Ship It

Close the gap between implementation-complete and actually shipped. Keep local
proof, hosted CI, approval, merge, tagging, and publication as separate states.

## Inventory

Gather current evidence in this order:

1. Working tree, current branch, recent commits, upstream, and branches ahead
   of the default branch.
2. Open PRs and the exact head, base, review, merge, and check state of any
   release-shaped PR.
3. Changeset or release-plan state when the repository uses one.
4. Source version, package registry versions and dist-tags, Git tags, and
   hosted release artifacts.
5. Required CI state and any approval or environment gates.
6. Repository visibility or publication prerequisites when relevant.

## Classify

Separate every remaining step into:

- **Authorized and reversible:** scoped source fixes, changelog updates,
  version changes, release notes, and feature-branch or PR work allowed by the
  user's request and repository policy.
- **Needs explicit authority:** default-branch pushes, merges, first
  publication, stable-channel promotion, visibility changes, deletions, or any
  other consequential public action not already requested.

Do not label an action safe merely because a CLI supports it. Consider its
external effect and the authorization already granted in the conversation.

## Execute And Verify

Perform every authorized step, one reviewable concern at a time. Follow the
global Git and PR policy for initial branch publication and subsequent pushes.
After each external action, re-read the remote state and verify the resulting
tag, artifact, version, checksum, or dist-tag at the boundary users consume.

Stop at the first step that needs new authority and provide the exact command
or UI action the user must approve.

## Report

State what shipped, distinguish it from what merely passed locally, list the
remaining human gates, and end with the standard `What's next:` handoff line.
