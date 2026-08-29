---
name: pr-description
description: Draft or revise an evidence-backed pull request body for a non-Composio repository. Use for PR descriptions or templates; defer Composio projects to their repository guidance.
---

# PR description

Describe the change a reviewer must evaluate. Keep the body aligned with the final committed diff, the repository template, and verification that actually ran.

## Establish the boundary

1. Inspect all Git remotes, the repository path, and local instructions before drafting.
2. If the project belongs to Composio or is a fork or checkout of a Composio repository, stop using this skill. Use `composio-pr` when it covers that repository; otherwise follow its local guidance.
3. Draft only unless the user explicitly asked to create or update the live pull request.

Proceed only after confirming that the repository is outside Composio and whether the requested output is a draft or a live change.

## Gather evidence

1. Read repository instructions and every applicable pull request template, including templates under `.github/PULL_REQUEST_TEMPLATE/`.
2. Establish the exact base and head. For an existing pull request, prefer its live GitHub refs and committed diff over stale local tracking branches.
3. Read the commit list, diff stat, and full diff. Check the final working tree so uncommitted work is not described as shipped.
4. Read the linked issue or user request when available.
5. Record user-visible behavior, public contract changes, migration needs, risks, and verification results. Treat skipped or pending checks as missing evidence.

Finish this pass with every planned claim traceable to the diff, issue, or observed verification output.

## Write the body

Honor required headings and checklists from the repository template. Within that structure, include only material that helps review:

- Lead with the concrete outcome and motivation when the motivation is not obvious.
- Describe behavioral and contract changes, using exact domain names and code identifiers.
- Explain migration steps for breaking changes with verified before-and-after usage when useful.
- Report only checks that completed, with commands or check names precise enough to identify them.
- Add issue links, screenshots, rollout notes, or risk notes only when they apply.

Let the change determine the structure. A small fix may need one sentence and two bullets; a broad change may earn short `Why`, `What changed`, `Verification`, or `Migration` sections. Do not impose a fixed heading set or bullet count.

Keep the prose authored and economical:

- Start with the result instead of a canned `This PR:` opening.
- Explain intent and effect instead of inventorying files.
- Remove title repetition, process narration, empty sections, vague intensifiers, and unsupported praise.
- Use bullets for genuine lists, not to fragment a paragraph.
- Preserve known uncertainty instead of presenting an inference as fact.

## Deliver and verify

For a draft, return the proposed Markdown body without claiming that GitHub changed.

For an authorized live update, send the body through literal stdin or a literal file so shell interpolation cannot alter Markdown. Re-read the live body afterward.

Before finishing, compare the description with the final committed diff and confirm:

- every substantive claim has evidence;
- required template content remains present;
- breaking behavior and migration guidance are explicit;
- verification statements match completed checks;
- no section or sentence exists only to make the body look complete.
