---
name: jk-review
description: Review diffs, PRs, plans, or specs for correctness, architecture drift, missing tests, and scope creep. Use when changes are about to ship, when a plan needs sanity-checking before execution, or when a spec needs to be stress-tested. Returns a structured findings report grouped by severity.
---

# jk-review

A review is a second pair of eyes, not a checklist. The job is to surface things the author can't see because they wrote it: load-bearing assumptions, scope creep, missing tests, drift from the repo's conventions, and silent regressions.

This skill produces a structured report. It does not auto-fix. The author decides what to address and when.

## Scope

Review targets:
- **Diff.** Staged changes, branch vs main, or a specific commit range.
- **Pull request.** A GitHub PR (use `gh pr view` and `gh pr diff`).
- **Plan.** A PLAN.md or similar before execution starts.
- **Spec.** A SPEC.md or similar before planning starts.

Not in scope:
- Style nitpicks the linter already catches. If the project has Biome, eslint, prettier, or rubocop wired up, trust them.
- Personal-preference rewrites. "I would have done it differently" is not a finding.

## Protocol

1. **Identify the target.** Diff, PR, plan, or spec. If ambiguous, ask.
2. **Read it in full once before forming opinions.** Skim invites the kind of comment that misses context two paragraphs down.
3. **Read the surrounding code (for diffs and PRs).** Open every file the diff touches and read the function before and after the changed lines. Many findings come from context the diff doesn't show.
4. **Build a findings list.** Each finding gets a severity (P1/P2/P3), a one-line summary, a quoted location, and a concrete suggested action.
5. **De-duplicate.** If three findings boil down to the same issue, merge them.
6. **Write the report.** Markdown, in the structure below.

## Severity definitions

Calibrate honestly. Severity inflation makes the whole report less useful.

**P1 (blocks merge).** Security vulnerability, data corruption risk, missing test for new behavior, broken backwards-compatibility on a stable API, factually wrong claim in a plan or spec, or anything that will cause an incident.

**P2 (should fix before merge, but mergeable with author sign-off).** Architectural drift, performance regression, naming inconsistencies that will calcify, missing error handling at a real boundary, ambiguity in a plan that would cost a re-spec cycle.

**P3 (nice to have).** Code that works but could be tighter, comments that explain what instead of why, an opportunity to extract a helper, a doc that could be clearer.

If everything is P1, calibration is broken. If everything is P3, the review wasn't done.

## What to look for

Apply the lenses that fit the target. Don't run all of them on everything.

### For diffs and PRs

- **LLM tells.** Comments that restate code, defensive checks for cases that can't happen, banner comments at file tops, `try/catch` around things that don't throw, `Record<string, unknown>` where a real type exists.
- **Tests vs claims.** Does the diff add or modify behavior without touching tests? Why?
- **Errors that swallow.** `catch {}` blocks, `Promise.catch(() => {})`, error messages that don't include the trigger context.
- **Hidden coupling.** A change in file A that silently requires a change in file B. Surface it.
- **Naming drift.** New code that uses different conventions from existing code (snake_case here, camelCase there).
- **Backwards-compatibility breaks.** Renamed or removed exported names, changed function signatures, removed CLI flags.
- **Security surface.** New input parsers, new shell-outs, new file-system writes, new credentials handling. Each gets a careful pass.
- **Performance traps.** N+1 queries, synchronous I/O in hot paths, unbounded growth in memory.
- **Dead code.** Functions/imports/types defined but unused.
- **Scope creep.** Did the diff add anything not justified by the PR title or linked spec/plan?

### For plans

- **Internal contradictions.** Does the plan say X in one section and ¬X in another?
- **Underspecified mechanics.** Commands referenced without contracts. Schemas referenced without fields. Paths referenced without expansion rules.
- **Self-evident scope.** Are the commits actually self-contained? Does the build stay green after each?
- **Hidden ordering.** Are dependencies between commits surfaced?
- **Missing flows.** Install but not uninstall. Create but not delete. Forward but not migration.
- **Open Questions not closed.** A plan with open questions isn't ready to execute.
- **Test plan as afterthought.** Every commit's done-when criterion must be verifiable.

### For specs

- **Goals vs Non-Goals.** Are both explicit? Vague Non-Goals invite scope creep.
- **Constraints stated.** Time, compatibility, dependencies. Not just "build it well".
- **Audience named.** Who is this for? "Users" is not an answer.
- **Success criteria measurable.** Not "users love it"; "passes test suite", "ships by date X", "supports use case Y".
- **Rejected alternatives.** What other approaches were considered? Why ruled out?

## Report format

```markdown
# Review: <target description>

## Summary
<one or two sentences: overall direction, top concern>

## P1 (blocks merge)
- **<one-line summary>** at <file:line or section>.
  <one-paragraph explanation>
  **Suggest:** <concrete action>

## P2 (should fix)
<same shape>

## P3 (nice to have)
<same shape>

## What's working well (optional)
<one or two specific positives. Skip if there's nothing notable.>
```

Keep findings concrete. Quote the line or paragraph you're referring to. "Use --force" is not a suggestion; "Add a `--force` flag that bypasses the conflict check" is.

## Anti-patterns in the review itself

- **Sycophancy.** "Overall great work!" with no specifics is filler. Skip.
- **Bikeshedding.** Two-line debates on variable names when there's an architectural issue lower down.
- **Speculation as finding.** "This might break under load" without a reason is noise. Either form the hypothesis with evidence or drop it.
- **Lecture mode.** "It's important to remember that..." If the author already knows this, you're padding. If they don't, link the canonical reference and move on.
- **Findings without locations.** "There are some issues with error handling" forces the author to scavenge. Quote the line.

## Operational notes

- **For multi-file reviews, run searches and reads in parallel.** Read the spec, the plan, and three relevant files concurrently. The point of a review is to be fast enough that the author hasn't moved on.
- **Defer to the linter.** Don't repeat what the project's tooling already flags.
- **Respect the author's stated scope.** A spec-only review doesn't critique implementation. A diff-only review doesn't second-guess the spec.
- **End with a single sentence summary the author can quote.** "Two P1s and three P2s; safe to merge after addressing P1s and confirming the P2 about target_conflict semantics." That's what they need to know.
