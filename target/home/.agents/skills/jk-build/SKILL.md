---
name: jk-build
description: Build a feature through spec, plan, work, or safe-change phases. Use for new features, executing an approved plan, or a scoped verified edit.
argument-hint: "[spec|plan|work|safe-change]"
---

# jk-build

A four-phase build loop. Each phase has a contract: what it takes in, what it produces, when it's done. Pick the phase that matches your starting point and run it to completion before moving to the next.

| Phase | Input | Output | Done when |
|-------|-------|--------|-----------|
| spec | A rough idea | A written spec the human has reviewed | Constraints, scope, and success criteria are all named |
| plan | A stable spec | A commit list with dependencies | Every commit is self-contained and leaves the build green |
| work | An approved plan | Code + green tests + commits on the branch | Plan is fully checked off and tests pass |
| safe-change | A scoped edit request | The edit applied, verified, and documented | Tests green, docs updated, no regressions |

## Running a phase

The invocation argument, when present, names the phase. When absent, infer it: fresh work starts at `spec`, an approved PLAN.md in the repo means `work`, a single scoped edit means `safe-change`. When in doubt, default to `spec`.

Before doing anything else, read the file for the active phase and follow it exactly:

- [phases/spec.md](phases/spec.md)
- [phases/plan.md](phases/plan.md)
- [phases/work.md](phases/work.md)
- [phases/safe-change.md](phases/safe-change.md)

Read only the active phase's file; the others load when their turn comes.

## Cross-phase principles

- **Honesty about uncertainty.** If you guessed a name, a default, or a structure, say so when reporting. The human can correct cheaply now; expensively later.
- **Match the work to the phase.** Don't draft a spec while in work phase. Don't start coding while in plan phase. The phase boundary is the value.
- **Working documents stay local.** SPEC.md and PLAN.md are working artifacts. Don't commit them unless the repo's convention says to.
- **Tests are part of the deliverable.** A feature without tests is a feature with a deferred bill. The bill comes due.
- **Stop and re-spec when the ground shifts.** If a plan-phase decision turns out wrong during work, that's a signal to update the plan, not to hack around it.
