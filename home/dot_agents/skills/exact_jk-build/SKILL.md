---
name: jk-build
description: >-
  Phase-driven workflow for building a feature end to end. Four phases run
  in order. spec gathers intent and constraints. plan turns the spec into
  commit-sized units. work executes the plan one commit at a time.
  safe-change handles scoped edits where a full spec/plan cycle is overkill.
  Use when starting new work, when an existing plan needs to be executed,
  or when making a single change that still needs verification.
arguments:
  - name: phase
    description: >-
      One of spec, plan, work, or safe-change. Defaults to spec when
      starting fresh.
---

# jk-build

A four-phase build loop. Each phase has a contract: what it takes in, what it produces, when it's done. Pick the phase that matches your starting point and run it to completion before moving to the next.

The four phases:

| Phase | Input | Output | Done when |
|-------|-------|--------|-----------|
| spec | A rough idea | A written spec the human has reviewed | Constraints, scope, and success criteria are all named |
| plan | A stable spec | A commit list with dependencies | Every commit is self-contained and leaves the build green |
| work | An approved plan | Code + green tests + commits on the branch | Plan is fully checked off and tests pass |
| safe-change | A scoped edit request | The edit applied, verified, and documented | Tests green, docs updated, no regressions |

Run the phase named by `$phase`. If `$phase` is unset, default to `spec`.

---

## Phase: spec

Goal: produce a written spec the human approves before any code is touched. Specs prevent the "we built the wrong thing" failure mode that costs hours.

### Inputs

The user's request, the current repo state, and any prior conversation. Sometimes a Linear issue, a Slack thread, or a screenshot.

### Protocol

1. **Read first.** Skim the repo's README, AGENTS.md (if present), and the top-level directory layout. Don't ask the human questions the codebase already answers.
2. **Surface what's missing.** Identify what you don't yet know that you'd need to build the thing well. Group questions into:
   - **Intent.** What is the user trying to accomplish? Why now?
   - **Constraints.** Time budget, compatibility, dependencies allowed or forbidden, platforms.
   - **Audience.** Who will use this? An end user? A teammate? A future agent?
   - **Scope.** What's in. What's explicitly out.
   - **Success criteria.** How will we know it worked? A passing test? A green CI? A demo?
   - **Rejected alternatives.** What other approaches were considered? Why were they ruled out?
3. **Ask in batches.** Use `AskUserQuestion` with focused single-select options when there are real choices. Three to four questions per batch is the sweet spot. Don't ask one question at a time and don't ask twelve.
4. **Write the spec.** Markdown, in a SPEC.md or similar local working doc (gitignored if the repo convention says so). Sections: Goals, Non-Goals, Constraints, Decisions, Open Questions. Open Questions should be empty before moving to plan.

### Outputs

A SPEC.md the human has read and confirmed. If the human says "looks good" or equivalent, the spec is stable.

### When to stop and ask vs. when to decide

Stop and ask when:
- A decision affects API surface, persisted data, or external integration.
- Two reasonable approaches both look defensible.
- The cost of guessing wrong is more than one commit's worth of work.

Decide and report when:
- It's a local style or naming choice.
- It's a default value that's easy to flip later.
- The repo's conventions already imply one answer.

Match the cost of asking to the cost of being wrong.

---

## Phase: plan

Goal: turn a stable spec into a list of commits, each self-contained and each leaving the build green.

### Inputs

A SPEC.md the human has approved. The current repo state.

### Protocol

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

### Outputs

A PLAN.md the human has approved. Open Questions empty.

### Pitfalls

- **Too-small commits.** "Add empty file" then "fill in file" is two commits where one was the unit. Combine.
- **Too-large commits.** "Add user auth (with database, API, UI, tests)" is multiple commits. Split.
- **Hidden ordering.** If commit N+1 requires commit N's schema, say so. Don't let a future-self merge them out of order.
- **Test plan as afterthought.** Every commit's "done when" should reference a verifiable signal. "Looks right" is not a signal.

---

## Phase: work

Goal: execute the plan one commit at a time, with verification after each.

### Inputs

A PLAN.md the human has approved. A clean working tree (or an in-progress branch).

### Protocol

1. **Read the plan top to bottom before touching code.** Look for changes since the plan was written.
2. **Pick the next commit.** The first unchecked item in the Commit Plan. Don't skip ahead unless the human reordered.
3. **Implement.** Follow the repo's existing patterns. Grep for similar code before inventing. Match naming conventions exactly.
4. **Verify continuously.** Run tests after each meaningful change, not at the end. Type-check if the language supports it. Linter if the repo runs one.
5. **Commit when the logical unit is complete.** Stage specific files (not `git add .`). Write a conventional commit message focused on the why, not the what. The diff already shows what.
6. **Update the plan.** Tick the commit off. If you learned something that changes a later commit, write it down in the plan now.
7. **Loop.**

### Outputs

Each commit lands on the branch with tests green. The plan is fully checked off.

### Pitfalls

- **`git add .` swallows surprises.** Always list files explicitly. The five extra seconds catch the accidental `node_modules/` or local working doc.
- **Reverting on autopilot.** If you hit a wall, stop. Read the failure. Don't `git reset --hard` to make the problem go away.
- **Commit message slop.** "Update apply.ts" tells the reader nothing. "feat: discriminated union for Plan; switch dispatch" tells them what changed and why.
- **Skipping tests "just for now".** Restoring skipped tests is the work item that never gets done. Don't skip.

---

## Phase: safe-change

Goal: make a single scoped edit with full verification, when a spec/plan cycle would be overkill.

Use for: a bug fix, a rename, a single-flag addition, a docs update, a small refactor. Not for: anything that changes API surface, persisted data, or external behavior more than locally.

### Protocol

1. **Preflight.** Read the file you're about to change. Read its callers (grep for the function name, the import). Identify what the change must preserve.
2. **Design or diagnose.**
   - For a **change**: pick one approach. Note one alternative you considered and rejected. Note any callers that will need to update.
   - For a **bug**: reproduce it first. Write a failing test if possible. Identify the root cause before patching.
3. **Implement the minimum.** Don't refactor surrounding code. Don't tidy. Don't add error handling for cases that don't happen. The diff should be small enough to read in one screen.
4. **Verify.** Run the relevant tests. Run the full suite if the change touches shared code. Smoke-test by hand if there's a CLI or UI to invoke.
5. **Update docs.** If the change touches public API, README, CHANGELOG, or in-repo docs, update them in the same commit.
6. **Commit.** One commit, conventional message.

### Outputs

A single small commit. Tests green. Docs in sync.

### When to escalate to spec/plan

If during step 1 or 2 you realize:
- The change requires a schema migration → escalate to spec/plan.
- The change cascades into more than three other files → escalate.
- You can't articulate the "done when" criterion → escalate.

Better to escalate early than to ship a "small change" that breaks production.

---

## Cross-phase principles

- **Honesty about uncertainty.** If you guessed a name, a default, or a structure, say so when reporting. The human can correct cheaply now; expensively later.
- **Match the work to the phase.** Don't draft a spec while in work phase. Don't start coding while in plan phase. The phase boundary is the value.
- **Working documents stay local.** SPEC.md and PLAN.md are working artifacts. Don't commit them unless the repo's convention says to.
- **Tests are part of the deliverable.** A feature without tests is a feature with a deferred bill. The bill comes due.
- **Stop and re-spec when the ground shifts.** If a plan-phase decision turns out wrong during work, that's a signal to update the plan, not to hack around it.
