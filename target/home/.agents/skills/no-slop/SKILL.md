---
name: no-slop
description: Remove low-evidence code and formulaic technical prose while preserving intent, and install the bundled anti-slop Oxlint rules. Use for no-slop or anti-slop requests, configuring opinionated TypeScript lint policy, writing that sounds AI-generated, and TypeScript work involving broad types, unsafe assertions, vague names, hidden control flow, weak tests, or narrating comments.
---

# No slop

Treat slop as work that claims more than it proves. Remove it without flattening the author's intent or rewriting sound code for taste.

## Principles

- Preserve evidence. Keep known values, keys, invariants, and source facts visible.
- State the exact thing. Prefer domain names and direct claims over generic containers or abstract labels.
- Contain uncertainty. Parse and normalize external input once per ownership boundary. Resolve process configuration at the composition root.
- Prefer direct mechanics. Make data flow, control flow, and ownership easy to follow.
- Make every layer earn its place. An abstraction, guard, test, comment, or sentence must add information or enforce a contract.
- Keep deliberate voice. Remove formulas and filler, then check that the result still sounds authored.

## Work

1. Read the full target and its local conventions.
2. Identify the claims the code or prose makes.
3. Collect low-evidence candidates before changing them.
4. Check each candidate against context. Keep intentional choices that carry meaning.
5. Make the smallest coherent edit that improves precision.
6. Verify the changed contract at its real boundary.
7. Report the result, the evidence, and any remaining uncertainty.

## TypeScript

Read [TypeScript](references/typescript.md) before writing or reviewing TypeScript or JavaScript. When the task evaluates, configures, fixes, or installs no-slop Oxlint rules, also read [Oxlint policy](references/oxlint.md). Apply repository rules first. Use these references as strict defaults, not permission for an unrelated rewrite.

## Technical prose

- Put the result, claim, or decision first.
- Cut throat-clearing, verdict fragments, repeated summaries, unsupported praise, and vague intensifiers.
- Do not pad a list or manufacture a contrast for rhythm.
- Preserve facts, numbers, names, citations, structure, and deliberate phrasing during a wording-only pass.

## Guardrails

- Do not replace valid dynamic behavior or explicit uncertainty only to satisfy a heuristic.
- Do not expand a local cleanup into a broad refactor.
- Do not invent compatibility paths, fallbacks, recovery behavior, or defensive checks without evidence.
- Do not add tests for unchanged behavior, trivial wiring, generated code, or implementation details.
- Do not weaken types, lint rules, assertions, or tests to make a check pass.
- Do not present a style preference as a correctness finding without evidence.
