---
name: bro
description: Restate the last assistant message in plain, concise language using pstack's bro skill. Use when the user requests bro or /bro.
disable-model-invocation: true
---

Run `pstack-skill path bro` (or `~/.local/bin/pstack-skill path bro`),
read the returned `SKILL.md`, and apply it in the current conversation.
Resolve bundled dependencies relative to that upstream collection; read only
what the task needs. The invocation argument is the user's additional request.
