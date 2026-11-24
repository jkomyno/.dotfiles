---
name: proof-skills
description: Load the proof-skills Lean and Mathlib collection only when explicitly requested by the user.
disable-model-invocation: true
---

Use this collection only when the user explicitly requests proof-skills in the
current session. Read `~/.local/share/proof-skills/skills/lean-gateway/SKILL.md`
and select relevant skills from `~/.local/share/proof-skills/skills/` for the
task. Read their SKILL.md files and referenced resources as needed; resolve
collection-relative paths against `~/.local/share/proof-skills`.

This is the standalone skill collection and its tracked resources. Its git
submodules and embedded MCP server are not installed. Use the separately
configured Lean LSP MCP when available. Do not install dependencies or run
project setup scripts unless needed and authorized for the task.
