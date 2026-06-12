# Shared Agent Instructions

These instructions apply to every coding agent on this machine (Claude Code, Codex, and future harnesses). Harness-specific entrypoints (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) import this file so guidance is written once.

## Conventions

- Never add AI attribution to commits, PRs, or code: no `Co-Authored-By: Claude`, no "Generated with" trailers, no tool links.
- Write commit messages in Conventional Commits style (`feat:`, `fix:`, `chore:`, ...), imperative mood, small and scoped.
- Prefer `rg` for searching over `grep -r` and `find`.

## Skills

Shared first-party skills live in `~/.agents/skills/`. Each harness exposes them through symlinks in its own skills directory (`~/.claude/skills/`, `~/.codex/skills/`). Edit skills in the dotfiles repository, not in the deployed copies.
