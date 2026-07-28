# AGENTS.md

- First, read `~/.agents/AGENTS.md` and apply everything in it.
- Then apply the Codex-only guidance below.

## Codex Only

- Default to concise, outcome-first responses. Omit routine narration and
  explanations unless they clarify a risk, tradeoff, or blocker.
- Keep verification proportional to the change's scope and risk. Prefer existing
  tests and the narrowest relevant checks.
- Add or modify tests only for changed behavior, bug regressions, or previously
  untested public contracts. Do not add tests for unchanged behavior, trivial
  wiring, generated code, or implementation details unless the repository
  explicitly requires them.
- Do not expand a change solely to improve test coverage. Run the full suite only
  when repository guidance or cross-cutting risk warrants it.
