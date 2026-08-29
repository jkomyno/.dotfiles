---
name: unlazy
description: "Prove substantial work complete with file-backed gates and runnable checks. Use for exhaustive completion, a Depth Tree, or a completion ledger."
---

# Unlazy

Use durable evidence when ordinary planning and verification are not enough. The
distinctive mechanism is a gate ledger; rely on the host's existing rules for
scope, safety, planning, testing, and communication.

## Start with gates

Before implementation, create `GATES.md` from
[`templates/gates-leaf.md`](templates/gates-leaf.md). Read
[`references/gates.md`](references/gates.md) before writing the first ledger.

- State observable outcomes, not activities.
- Give each automatable gate a `CHECK`, decisive `EXPECT`, and `EVIDENCE`.
- Keep manual evidence short and concrete: a measurement, deciding output, or a
  file and line.
- Preserve an impossible gate with `ABANDON: <id> <reason>` and report it; never
  silently narrow scope.

Run checks and update the ledger with:

```bash
node <this-skill-dir>/scripts/gate-check.mjs GATES.md
```

Use `--status` for a read-only ledger check. Keep gate files uncommitted unless
the repository treats execution ledgers as project artifacts.

## Choose the smallest mode

- **Solo, by default:** one `GATES.md`, one coherent task, no orchestration.
- **Depth Tree:** only for an explicit `tree N` request or work too large for one
  context. Read [`references/method.md`](references/method.md), then create the
  plan and ledgers from `templates/`.
- **Orchestrated:** only when the host permits subagents and fresh contexts
  materially help. Read
  [`references/orchestration.md`](references/orchestration.md), assign disjoint
  ownership, add branch integration gates, and have the parent rerun leaf
  checks. Respect the host's concurrency and delegation rules.

For long runs, consult
[`references/token-economy.md`](references/token-economy.md) and keep leaf briefs
to their contract plus ledger.

## Finish against evidence

1. Run the ledger checks and resolve every unmet gate.
2. Adversarially inspect at least one passed gate and correct weak evidence.
3. Remeasure every number used in the final report.
4. Report the met-gate count and every abandoned gate. Do not claim full
   completion when anything remains unmet.

Claude Code can optionally enforce ledgers with `scripts/stop-hook.mjs`. Never
install its hook without the user's explicit approval; use
`scripts/install-hooks.mjs --uninstall` to remove it.
