# jk-build — phase: plan

Goal: turn a stable spec into a list of commits, each self-contained and each leaving the build green.

## Inputs

A SPEC.md the human has approved. The current repo state.

## Protocol

1. **Walk the spec.** For each goal, identify the minimum code that has to land. Look for natural seams: one model, one endpoint, one component, one CLI flag.
2. **Draft a commit list.** Each commit gets a one-line conventional-commit title (`feat:`, `chore:`, `refactor:`, etc.) and a one-paragraph description.
3. **Apply the per-commit invariants.** Every commit:
   - Is self-contained (someone could revert it cleanly).
   - Leaves the build green (tests pass, linter passes, types check).
   - Has a clear "done when" criterion.
4. **Identify dependencies.** Note which commits block which. Surface any hidden coupling (e.g., commit 3 schema → commit 5 code that reads it).
5. **Flag risk.** Mark commits that are likely to balloon (cross-cutting refactors, schema migrations, anything touching the install path).
6. **Write the plan.** Markdown, PLAN.md. Sections: Summary, Key Decisions, Repository Layout (if changes), Commit Plan, Test Plan, Open Questions, Out of Scope.
7. **Confirm.** Read the plan back to the human. Specifically call out: scope cuts you made, decisions you guessed at, anything that surprised you.

## Outputs

A PLAN.md the human has approved. Open Questions empty.

## Pitfalls

- **Too-small commits.** "Add empty file" then "fill in file" is two commits where one was the unit. Combine.
- **Too-large commits.** "Add user auth (with database, API, UI, tests)" is multiple commits. Split.
- **Hidden ordering.** If commit N+1 requires commit N's schema, say so. Don't let a future-self merge them out of order.
- **Test plan as afterthought.** Every commit's "done when" should reference a verifiable signal. "Looks right" is not a signal.
