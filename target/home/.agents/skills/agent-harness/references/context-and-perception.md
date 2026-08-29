# Context and perception

An agent's eyes are every signal available at the moment it makes a decision,
not only the prompt or retrieved documents.

## Inventory

For each signal, record its source, authority, freshness, size bound, update
rule, and failure mode:

- system and repository instructions;
- user intent and acceptance criteria;
- conversation history and summaries;
- durable memory and prior decisions;
- retrieved documents, code, search candidates, and citations;
- tool names, schemas, permissions, results, errors, and truncation markers;
- current plan, working-tree state, remote state, and deterministic status;
- browser viewport, images, audio, or other modality-specific observations.

Classify each signal as static or dynamic, authoritative or advisory, and
durable or ephemeral. Conflicts must resolve through a stated precedence rule.

## Assembly

Keep the reusable prefix stable: policies, domain contract, tool definitions,
and durable conventions. Append dynamic material in a fixed order:

1. current task and success criteria;
2. selected evidence with stable identifiers;
3. current state, completed work, and unresolved failures;
4. available actions and permissions;
5. the required output contract.

Progressively disclose detail. Start with compact candidates, then fetch a
bounded section or object, then raw material only when needed. Compression must
be query-aware and retain decisions, constraints, attempted fixes, failures,
source identifiers, and open questions. Summaries are replaceable caches, not
the source of truth.

## Perception tools

- Search returns candidate identifiers, source, score or rationale, a short
  preview, and a continuation token.
- Detail reads accept stable identifiers plus offsets, sections, or page ranges.
- Every response declares its bounds and whether content was omitted.
- Read-only calls may be cached, batched, and parallelized when their ordering
  does not affect meaning.
- Errors explain whether the problem is absence, permission, parsing, timeout,
  stale state, or an invalid request and provide the next safe action.
- Long documents expose an outline or page map before full extraction.
- Compound questions preserve which evidence supports each sub-answer.
- Text is the default for semantics; rendered pages are required for layout,
  tables, figures, forms, or other spatial evidence.

## Observability

Record the context manifest, tool request, bounded response, selected evidence,
decision, action result, verification, and correction. Sensitive values may be
redacted, but the trace must still show why each decision was possible.
