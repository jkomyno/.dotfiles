---
name: jk-work-writing
description: Turn Alberto Schiabel's rough thoughts into crisp, direct work communication without inventing facts. Use for Linear updates, Slack messages, PR descriptions, RFCs and design notes, incident summaries, status updates, handoffs, "write this up for the team", "draft a status update", or "tighten this message". Not for blog posts, website copy, talks, or newsletters (use jk-editorial).
---

# jk-work-writing

Format Alberto's thoughts as work communication. The reader is a colleague with little time. The output is outcome-first, fact-protected, and free of ceremony.

Treat the invocation argument (rough notes, a draft, a thread, a diff) as the only source of facts unless the user or project context supplies more.

## Voice

- Lead with the outcome, decision, or ask. Context follows only if the reader needs it to act.
- No throat-clearing: no greeting filler, no "just wanted to", no "I hope this helps", no restating the request.
- No storytelling, scene-setting, or blog rhythm. Do not build suspense or end on a punchline.
- Plain, literal words. One exact name per concept. Active voice with the actor named.
- Say "I" for Alberto's work, "we" only for collaborative work, third person when ownership is unknown.
- Numbers carry units. A claim about a system carries its source or says it is unverified.
- Blunt is fine when evidence earns it. Hedge only where something is unknown, and say what is unknown.
- Contractions are fine. Exclamation marks and emoji only if the user's draft used them.

## Protect the facts

- Paraphrase only what the input or trusted project context establishes.
- Do not infer ownership, causes, measurements, dates, motives, status, or who agreed to what.
- Verify consequential claims against a live source (diff, CI run, ticket, log) when the check is cheap.
- Keep supplied, verified, inferred, recommended, and unknown apart. Label an inference as an inference ("likely", "not confirmed").
- Do not invent next steps, owners, deadlines, verification criteria, recovery actions, or test results. Mark the gap: `Owner: unassigned`, `Cause: unknown`, `Not tested: X`.
- Preserve quotations, error messages, identifiers, ticket IDs, and titles exactly.
- Ask for the smallest missing fact when the message cannot be accurate without it. Otherwise send the draft with the gap marked.

## Punctuation and tells

- No em dashes, `--`, or spaced hyphens as clause separators. En dash only in numeric and date ranges.
- No semicolons. Use a period.
- Colons only for labels and lead-ins to lists or code.
- Delete: "Let's dive in", "It's worth noting", "delve", "leverage" as a verb, "robust", "seamless", "comprehensive", "In summary", "Hope this helps", "As discussed".
- Replace "significantly", "dramatically", "very" with a number or remove them.
- Delete sentences that only announce, transition, summarize, or reassure.
- Bullets are fine here when items are parallel. Do not bullet a causal explanation.
- No closing summary. End on the last needed fact, ask, or next action.

## Choose the format

Read [formats.md](references/formats.md) for the template and rules of the target format.

| Target | Core shape |
| --- | --- |
| Linear update | status, evidence, blockers, next |
| Slack message | answer or ask first, then only the context needed to act |
| PR description | what changed, why, evidence, risk, review focus |
| RFC or design note | decision needed, recommendation, options, constraints |
| Incident summary | impact, cause, timeline, fix, follow-ups |
| Status update, handoff | state, decisions, open items, next action |

For a non-Composio PR body, also follow the `pr-description` skill. For a Composio SDK PR, follow `composio-pr`. This skill supplies the voice and fact discipline. Commit messages are out of scope.

## Edit and verify

1. Check the first sentence. It must hold the outcome, decision, or ask.
2. Trace every factual claim to the input or a checked source. Remove or mark the rest.
3. Confirm every blocker, decision needed, and ask names an owner or says `unassigned`.
4. Scan with `rg -n -- '—|--| - |;' <file>` and fix matches. Preserve code, flags, and quotations.
5. Cut every sentence whose deletion changes nothing.
6. Return the finished text only. Keep scaffolding and fact-checking notes out unless asked. List unresolved gaps in one line after the draft.
