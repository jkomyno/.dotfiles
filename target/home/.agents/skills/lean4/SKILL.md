---
name: lean4
description: Load the Lean 4 theorem proving workflows only when explicitly requested by the user.
disable-model-invocation: true
---

Use this skill only when the user explicitly asks for the lean4 skill in the
current session. Read `~/.local/share/lean4-skills/lean4/skills/lean4/SKILL.md`
and follow it for the requested task. Resolve its references relative to that
file. For a named workflow, also read the corresponding file under
`~/.local/share/lean4-skills/lean4/commands/`.

The portable helper runtime is at `~/.local/share/lean4-skills/lean4`.
For shell commands that need it, set `LEAN4_PLUGIN_ROOT` to that absolute path,
`LEAN4_SCRIPTS` to its `lib/scripts` directory, `LEAN4_REFS` to its
`skills/lean4/references` directory, and add its `bin` directory to PATH in
the same command. Do not assume shell environment changes persist between calls.
No upstream hooks or native plugin commands are installed.
