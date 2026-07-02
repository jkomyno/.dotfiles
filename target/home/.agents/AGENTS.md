# Shared Agent Instructions

These instructions apply to every coding agent on this machine (Claude Code, Codex, and future harnesses). Harness-specific entrypoints (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) import this file so guidance is written once.

## Conventions

- Never add AI attribution to commits, PRs, or code: no `Co-Authored-By: Claude`, no "Generated with" trailers, no tool links.
- Write commit messages in Conventional Commits style (`feat:`, `fix:`, `chore:`, ...), imperative mood, small and scoped.
- Prefer `rg` for searching over `grep -r` and `find`.

## Local repository notes

- If `AGENTS.local.md` exists at a repository's root, read it before starting work. It holds machine-local, untracked guidance: pointers to reference corpora under `~/.jk/ideas/<name>/`, environment quirks, and other context that must stay out of git history.
- Never commit `AGENTS.local.md`, add it to a tracked `.gitignore`, or quote its contents in commits, PRs, or tracked files. It is hidden by the global gitignore; the `jk-cli` skill maintains it.

## Skills

Shared skills live in `~/.agents/skills/`. Codex scans that directory natively; Claude Code reaches it through the `~/.claude/skills` directory symlink. Edit skills in `target/home/.agents/skills/` in the dotfiles repository, not in the deployed copies.

Conventions for authoring first-party skills, so one SKILL.md serves both harnesses:

- Frontmatter uses the shared fields (`name`, `description`) plus Claude Code extras (`argument-hint`, `disable-model-invocation`) that Codex silently ignores.
- No `$ARGUMENTS` or `$name` placeholders in skill bodies — Codex performs no substitution. Refer to "the invocation argument" in prose; Claude Code appends unconsumed arguments as `ARGUMENTS: <value>`.
- Keep descriptions under 1024 characters, leading with what the skill does and the phrases that should trigger it.
- Keep SKILL.md lean; move long per-mode instructions into bundled files the skill reads on demand (see `jk-build/phases/`).
