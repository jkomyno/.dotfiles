# Shared Agent Instructions

These instructions apply to every coding agent on this machine (Claude Code, Codex, and future harnesses). Harness-specific entrypoints (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`) import this file so guidance is written once.

## Conventions

- Never add AI attribution to commits, PRs, or code: no `Co-Authored-By: Claude`, no "Generated with" trailers, no tool links.
- Write commit messages in Conventional Commits style (`feat:`, `fix:`, `chore:`, ...), imperative mood, small and scoped.
- Prefer `rg` for searching over `grep -r` and `find`.

## Git & PR policy

- Never push directly to a repository's default or protected branch; deliver changes through a PR.
- A reviewed feature branch may be pushed once to establish its remote ref. Open its PR immediately, then keep every subsequent push on that linked PR branch.
- Push only after the feature is implemented, reviewed locally, and cleaned up.
- Fast tests and lint run locally; e2e runs on CI.
- When the task explicitly says commit or push, do the requested step without re-asking once its gates pass. Otherwise don't.
- Personal repos (`~/work/me/**`): looser — free commits and initial feature-branch publication; the default branch still requires a PR.
- Work repos and long-standing public repos: strict — no push without local review and green local checks.
- Once a plan is approved, execute end-to-end and report at completion.
- When finished, report: "What's next: <tl;dr>. <next prompt to copy>".

## Local repository notes

- If `AGENTS.local.md` exists at a repository's root, read it before starting work. It holds machine-local, untracked guidance: pointers to reference corpora under `~/.jk/ideas/<name>/`, environment quirks, and other context that must stay out of git history.
- Never commit `AGENTS.local.md`, add it to a tracked `.gitignore`, or quote its contents in commits, PRs, or tracked files. It is hidden by the global gitignore; the `jk-cli` skill maintains it.

## Shared memory

- Use agentmemory as the durable cross-agent memory layer when it is available. Search it before debugging a recurring class of issue, migration, release problem, or repo-specific workflow; save concise durable lessons after fixing one.
- Keep secrets, tokens, private machine state, and full transcript dumps out of memory. Store the reusable pattern, evidence path, and verification command instead.
- Runtime memory lives under `~/.agentmemory` and is not managed by these dotfiles.

## Skills

Shared skills live in `~/.agents/skills/`. Codex scans that directory natively; Claude Code receives per-skill links inside its host-owned `~/.claude/skills/` directory through `scripts/dotfiles/claude-skill-links.sh`. Edit skills in `target/home/.agents/skills/` in the dotfiles repository, not in the deployed copies.

Conventions for authoring first-party skills, so one SKILL.md serves both harnesses:

- Frontmatter uses the shared fields (`name`, `description`) plus Claude Code extras (`argument-hint`, `disable-model-invocation`) that Codex silently ignores.
- No `$ARGUMENTS` or `$name` placeholders in skill bodies — Codex performs no substitution. Refer to "the invocation argument" in prose; Claude Code appends unconsumed arguments as `ARGUMENTS: <value>`.
- Keep descriptions under 1024 characters, leading with what the skill does and the phrases that should trigger it.
- Keep SKILL.md lean; move long per-mode instructions into bundled files the skill reads on demand (see `jk-build/phases/`).
