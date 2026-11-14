---
name: potetomode
description: Load pstack's poteto-mode workflow for concise responses, deliberate delegation, simple code, and verified work. Use when the user requests potetomode or /potetomode.
disable-model-invocation: true
---

Run `pstack-skill path poteto-mode` (or
`~/.local/bin/pstack-skill path poteto-mode`), read the returned `SKILL.md`,
and apply it in the current conversation. Resolve bundled skills, agents,
scripts, and references relative to that upstream collection; read only what
the task needs. The invocation argument is the task to perform in this mode.
