---
name: handoff
description: Write a self-contained continuation prompt for the next session. Use for "handoff", "what's next", "give me the next prompt", or unfinished work crossing a session boundary.
---

# Handoff

Write a self-contained continuation prompt when work must continue in another
session. If the requested work is complete, say so instead of inventing more
work.

## Output Contract

1. Start with `What's next: <tl;dr>.` State the current result and single next
   move in one sentence.
2. Put the next prompt in a fenced block. Name the repository, branch, PR, key
   files, verified state, blockers, and done-when condition. Point to the
   repository's `AGENTS.md` instead of copying its conventions.
3. Add a short state block only when work remains: branch, PR, failing checks,
   blockers, and files still being edited.

## Rules

- Save a reusable lesson to agentmemory before the handoff only when the
  repository guidance permits memory writes. Store the pattern, evidence path,
  and verification command; never store secrets or transcript dumps.
- Suggest `ship-it` only when implementation is complete but publication,
  merge, tagging, or promotion remains.
- Keep the next prompt under roughly 150 words. Link existing context when
  available; ask before creating a tracked or local context file unless the
  user already authorized that write.
