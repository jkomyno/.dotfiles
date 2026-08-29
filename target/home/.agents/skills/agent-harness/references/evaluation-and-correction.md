# Evaluation and correction

Evaluate the harness, not only the model's final answer.

## Contract

For every task class, define:

- observable success and allowed variance;
- forbidden actions and authority boundaries;
- latency, cost, context, and tool-call budgets;
- required evidence and provenance;
- stop, retry, escalation, and recovery conditions.

## Test sets

Maintain two complementary sets:

- **Boundary set:** cases the current harness fails or nearly fails. Add the
  smallest case that isolates each discovered defect.
- **Retention set:** representative cases already solved. They prevent an
  improvement in one path from erasing a working capability elsewhere.

Keep a holdout set for claims of general improvement. Do not tune directly on
holdout failures.

## Trajectory checks

Score the decision path as well as the outcome:

1. Did the harness expose the necessary evidence?
2. Did the model select the relevant evidence?
3. Was the chosen action allowed, minimal, and reversible where possible?
4. Did verification test the actual boundary users depend on?
5. Did correction use the failure evidence, or merely repeat the attempt?
6. Did the run stop when complete or genuinely blocked?

Classify failures as perception, context assembly, reasoning, action,
verification, or recovery defects. Fix the earliest failing stage.

## Anti-gaming

- Prefer behavioral assertions over preferred wording.
- Use inverse cases and mutants to prove the evaluator rejects plausible wrong
  behavior.
- Keep the evaluator independent from the producer when practical.
- Preserve the original task and evidence outside any mutable summary.
- Compare against a baseline and report regressions, not only aggregate gains.
- Treat retries and hidden human intervention as measured costs.
