# jk-build — phase: safe-change

Goal: make a single scoped edit with full verification, when a spec/plan cycle would be overkill.

Use for: a bug fix, a rename, a single-flag addition, a docs update, a small refactor. Not for: anything that changes API surface, persisted data, or external behavior more than locally.

## Protocol

1. **Preflight.** Read the file you're about to change. Read its callers (grep for the function name, the import). Identify what the change must preserve.
2. **Design or diagnose.**
   - For a **change**: pick one approach. Note one alternative you considered and rejected. Note any callers that will need to update.
   - For a **bug**: reproduce it first. Write a failing test if possible. Identify the root cause before patching.
3. **Implement the minimum.** Don't refactor surrounding code. Don't tidy. Don't add error handling for cases that don't happen. The diff should be small enough to read in one screen.
4. **Verify.** Run the relevant tests. Run the full suite if the change touches shared code. Smoke-test by hand if there's a CLI or UI to invoke.
5. **Update docs.** If the change touches public API, README, CHANGELOG, or in-repo docs, update them in the same commit.
6. **Commit.** One commit, conventional message.

## Outputs

A single small commit. Tests green. Docs in sync.

## When to escalate to spec/plan

If during step 1 or 2 you realize:
- The change requires a schema migration → escalate to spec/plan.
- The change cascades into more than three other files → escalate.
- You can't articulate the "done when" criterion → escalate.

Better to escalate early than to ship a "small change" that breaks production.
