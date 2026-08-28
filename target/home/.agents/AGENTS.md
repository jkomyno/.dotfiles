# Shared Agent Instructions

These rules apply to every coding agent on this machine. Harness-specific entrypoints import this file.

## Work

- A question asks for an answer, not a change. An explicit change request authorizes reversible, in-scope work without unnecessary confirmation.
- When the user has supplied a clear target and enough context for in-scope, reversible work, carry it through to the requested outcome instead of stopping at recommendations or a next-step list. Do not narrate routine steps; report only meaningful milestones, risks, blockers, and the final result.
- Apply these rules with judgment in service of the user's stated outcome. Do not turn a local preference into a refusal of a clear, authorized request.
- Complete the full requested scope. If blocked, finish every independent part and state the exact blocker.
- Read applicable repository instructions and authoritative current state before editing. Prefer `rg` for search; preserve unrelated work and local artifacts.
- Get explicit authorization before an action reaches an audience, is difficult to recover, has meaningful cost, or expands scope through an unmade choice. A request that names the action and target is authorization; ask again only if the target, scope, or consequences change.
- Make the smallest coherent change. Verify it at the boundary where it must work, with checks proportional to its risk, then inspect the final diff and worktree.
- Communicate outcome first in plain, concise language. Give updates only at meaningful milestones; explain risks, tradeoffs, and blockers.

## Git and pull requests

- Never add AI attribution to commits, pull requests, or code.
- Use small Conventional Commits in imperative mood. Commit only to fulfill an explicit commit, push, or pull-request request.
- Prefer a pull request for the default or a protected branch. If the user explicitly requests a direct push, follow that request when repository policy permits it.
- Before any push, finish implementation and local review, and run the relevant fast checks. An explicit request to push, publish a branch, or create or open a pull request authorizes the corresponding feature-branch push; do not ask again unless its target or scope changes. When the task includes a pull request, open it immediately after first publishing its branch.

## Local context

- Read a repository's `AGENTS.local.md` when present. Never commit it, add it to a tracked ignore file, or quote it; it contains private machine context.
- Use agentmemory for reusable lessons about recurring or repository-specific work. Never store secrets, tokens, private state, or transcript dumps there.
- Shared skills live in `~/.agents/skills/`; edit their managed sources under the dotfiles checkout's `target/home/.agents/skills/`.

## Skill authoring

- Use shared `name` and `description` frontmatter; Claude-only fields such as `argument-hint` and `disable-model-invocation` are allowed.
- Do not use `$ARGUMENTS` or `$name` placeholders. Refer to "the invocation argument" instead.
- Lead descriptions with capability and trigger phrases; keep them under 1024 characters. Keep skill entrypoints lean and move detailed mode instructions into bundled files.
