---
name: agent-harness
description: "Design or review an AI agent harness: context assembly and compression, perception tools, action tools, constraints, verification, correction, and evals. Use for agent runtimes, tool loops, coding agents, RAG or document agents, long-running workflows, and context or tool failures; not ordinary one-shot prompting."
---

# Agent Harness

Treat the harness as the runtime system around the model. Its job is to control
what the model can perceive, which actions it can take, and how results are
checked and corrected.

## Workflow

1. Define the task boundary, observable success, stop conditions, and actions
   requiring human authority. Finish when success and failure are measurable.
2. Map one decision loop: assemble context, decide, act, observe, verify,
   recover. Name the owner and output contract for every stage.
3. Inventory the agent's eyes: instructions, state, history, memory, retrieved
   evidence, tool schemas and output, errors, and environment feedback. Read
   [context and perception](references/context-and-perception.md) when designing
   or debugging these inputs.
4. Design narrow tools around decisions. Prefer candidate lists followed by
   bounded detail reads, stable identifiers, pagination, explicit truncation,
   and structured errors. Separate read-only perception from mutation.
5. Add constraints before actions, verification after actions, and a bounded
   correction path after failures. Make irreversible actions explicit.
6. Build the evaluation before broadening capability. Read
   [evaluation and correction](references/evaluation-and-correction.md) for the
   boundary, retention, trajectory, and anti-gaming checks.
7. Implement the smallest complete loop, record its inputs and outputs, run the
   focused evals, and inspect failures. Expand only when the trace shows a
   missing capability rather than a prompting preference.

## Non-negotiables

- Keep stable instructions and tool definitions in a reusable prefix. Append
  dynamic task evidence and state in deterministic order.
- Preserve decisions, constraints, failures, evidence identifiers, and current
  state during compression. Never hide truncation.
- Prefer text and structure for semantics; add images or screenshots when
  layout, geometry, or rendering is part of the decision.
- Keep the evaluator independent from the producer when practical.
- Retain unsuccessful trajectories. They explain whether the defect was in
  perception, reasoning, action, verification, or recovery.
