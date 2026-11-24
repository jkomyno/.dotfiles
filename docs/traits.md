# Traits from coding history

Twelve portable [Traits](https://github.com/crosshatch/traits) seeds live in
[`target/home/.agents/trait-seeds`](../target/home/.agents/trait-seeds/).
Mise exposes the collection at `~/.agents/trait-seeds`.

These were distilled from local Claude Code, Codex, and Pi history dated
2026-10-18 through 2026-11-17. The extraction selected user-role submissions,
removed repeated turns within a session, and searched for coding corrections.
The selected corrections were then checked in their conversation context.
User-role coordinator messages, pasted plans, and assistant recommendations were
not treated as independent user preferences. Terminal history indexes helped
corroborate direct submissions where available.

The seeds contain generalized requirements and scope exceptions. Raw
transcripts, quotations from private conversations, session identifiers, project
paths, and the evidence index stay outside this repository. The local extraction
and evidence report are under `~/.cache/traits-history/`.

## Seed collection

| Trait | Checks |
| --- | --- |
| `typed-domain-boundaries` | Parse external data and preserve domain types downstream. |
| `structured-internal-values` | Keep known internal fields structured until serialization. |
| `derive-defaults-from-definitions` | Derive secondary defaults from their owning definition. |
| `behavior-focused-tests` | Assert meaningful behavior or supported contracts. |
| `bounded-readiness-waits` | Wait for observable readiness with a bounded failure path. |
| `single-purpose-changes` | Keep independent work out of a targeted change. |
| `root-cause-fixes` | Repair the demonstrated cause of an observed defect. |
| `preserve-version-specific-fixtures` | Preserve intentional compatibility versions. |
| `domain-names-without-plan-ids` | Keep temporary plan labels out of code and tests. |
| `preserve-upstream-attribution` | Preserve relevant source citations during rewrites. |
| `target-measurements-for-performance-claims` | Ground performance claims in target measurements. |
| `compatibility-for-real-consumers` | Base compatibility obligations on actual contracts. |

## Use with existing subscriptions

The shared [`traits-review` skill](../target/home/.agents/skills/traits-review/SKILL.md)
checks these preferences inside the current Claude Code, Codex, or Pi session.
It uses the model and tools already serving that session and starts no separate
model API or reviewer process. Normal session usage still consumes the current
account's allowance. It does not add a separate paid API requirement.

The skill is eligible for automatic selection after substantive code changes
and during code review. For an explicit check, invoke `traits-review` using the
agent's skill interface. Claude Code exposes `/traits-review`, Codex accepts
`$traits-review`, and Pi can invoke `/skill:traits-review`.

The review uses applicable shared seeds and project traits, with a same-name
project trait replacing the seed. It inspects the actual diff and surrounding
code, so scope-sensitive rules can use task context. Confirmed findings name
the trait and source location. Missing context remains inconclusive.

This is an instruction-based self-review. Automatic skill selection is not a
mandatory execution hook or a CI gate, and the current agent can still miss a
problem. The workflow does not reproduce the official decision model or its
probability scores. Keep deterministic lint, types, and tests for the contracts
they can enforce.

## Optional upstream MCP setup

The shared directory is a seed library, not an active upstream Traits store. Traits currently
reads `<git-root>/.agents/traits/*.md` and `<git-root>/traits.ts`; it does not
automatically inherit global trait files. Copy applicable seeds into that
project's store after comparing them with its conventions and existing traits.
Preserve local changes when bringing in later seed revisions. Keep the SQLite
database and its sidecars ignored as described in the upstream setup guide.

Do not link a project's entire mutable store to the shared seed library:
project-local trait edits and database files must stay with their project.
The performance trait is useful for performance claims; the compatibility trait
requires known release and consumer status. Neither creates an obligation to run
benchmarks or investigate release status for unrelated work.

The existing [`no-slop` skill](../target/home/.agents/skills/no-slop/SKILL.md)
remains the broader coding workflow. Project instructions and contracts
determine trait applicability; the seeds do not override them.

Provider configuration and MCP registration are separate from extracting these
files. Follow the upstream [setup guide](https://github.com/crosshatch/traits/blob/main/SETUP.md)
in the chosen project, selecting decision and language-model providers before
creating `traits.ts`. This path requires provider configuration and is not
needed for the subscription-based skill. No provider, separate paid API calls,
or global MCP server is configured by this collection.

After setup, check final changed files, inspect surrounding code before accepting
a finding, and rerun relevant lint, types, and behavior checks after repairs.
An inconclusive assessment needs context. An empty report does not establish
that files were selected or that the repository is compliant.

## Validation and refresh

The initial validation checks the trait frontmatter, filename identities, and
scope qualifications. Review accuracy has not been measured on a held-out set.
Before treating the workflow as reliable, run it on known violations and valid
counterexamples, then measure useful catches, false alarms, and session usage on
real changes.

This is a one-time history import. It adds no background transcript reader or
automatic persistence hook. Future imports should preserve evidence locally,
compare against these seeds, and keep one-off stack choices and agent-generated
instructions out of general preferences.
