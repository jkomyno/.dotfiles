# jk-build — phase: work

Goal: execute the plan one commit at a time, with verification after each.

## Inputs

A PLAN.md the human has approved. A clean working tree (or an in-progress branch).

## Protocol

1. **Read the plan top to bottom before touching code.** Look for changes since the plan was written.
2. **Pick the next commit.** The first unchecked item in the Commit Plan. Don't skip ahead unless the human reordered.
3. **Implement.** Follow the repo's existing patterns. Grep for similar code before inventing. Match naming conventions exactly.
4. **Verify continuously.** Run tests after each meaningful change, not at the end. Type-check if the language supports it. Linter if the repo runs one.
5. **Commit when the logical unit is complete.** Stage specific files (not `git add .`). Write a conventional commit message focused on the why, not the what. The diff already shows what.
6. **Update the plan.** Tick the commit off. If you learned something that changes a later commit, write it down in the plan now.
7. **Loop.**

## Outputs

Each commit lands on the branch with tests green. The plan is fully checked off.

## Pitfalls

- **`git add .` swallows surprises.** Always list files explicitly. The five extra seconds catch the accidental `node_modules/` or local working doc.
- **Reverting on autopilot.** If you hit a wall, stop. Read the failure. Don't `git reset --hard` to make the problem go away.
- **Commit message slop.** "Update apply.ts" tells the reader nothing. "feat: discriminated union for Plan; switch dispatch" tells them what changed and why.
- **Skipping tests "just for now".** Restoring skipped tests is the work item that never gets done. Don't skip.
