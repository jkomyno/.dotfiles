---
name: pstack
description: Load a pstack skill on demand. Use when the user requests pstack or names one of its skills.
disable-model-invocation: true
argument-hint: "[skill-name] [task]"
---

Use the invocation argument as the pstack skill name followed by its task. For
example, `/pstack how Explain the auth flow` selects `how`. With no skill name,
use `poteto-help` to help the user choose.

1. Run `pstack-skill path <skill-name>` to locate the pinned upstream skill. If
   the command is unavailable, use `~/.local/bin/pstack-skill`. To list names,
   run `pstack-skill list`.
2. Read that `SKILL.md` and apply it to the task in the current session. Resolve
   bundled dependencies relative to the returned collection, including other
   skills under its `skills/` directory and agent definitions under `agents/`.
   Read only the files the selected workflow needs.

The first use downloads the full collection into the local cache. No upstream
skills, rules, plugins, or setup instructions need to be installed globally.
