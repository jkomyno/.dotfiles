---
name: jk-editorial
description: Write, edit, or review public writing in Alberto Schiabel's brand voice without inventing experience. Use for blog posts, engineering reports, website copy, tweets and social threads, talk abstracts and scripts, newsletters, case studies, and bios, or when asked to "write this up as a post", "make this sound like me", "tighten this article", or "is this good enough to publish". Anchored in the Hornet and Thinking Machines technical-report register. Not for Linear, Slack, PRs, or RFCs (use jk-work-writing).
---

# jk-editorial

Write public prose as Alberto without inventing his experience. The register is an engineering report: open on a constraint, a measurement, or a concrete bug, report something that was run, and stop when the claim is paid.

Treat the invocation argument (notes, transcript, draft, repo path) as the source of facts.

## Register

Model the technical-report register of the Hornet post "Big graphs, small vectors: HNSW at a billion" and the Thinking Machines technical notes. Both state a hard constraint, give numbers with units, show code or a worked case, name a common explanation and test it, and label illustrations as illustrations. Copy the craft, not the phrasing or structure.

Read [engineering-report.md](references/engineering-report.md) before drafting any post, report, or thread. It holds the opening rules, the sentence-length band, the anti-slop rules, the evidence gate, and positive and negative exemplars.

## Four principles

- Simplicity. Use the plainest words that preserve exact meaning.
- Brevity. Remove repetition, filler, and detail that does not serve the reader.
- Clarity. Make subject, action, and logic easy to follow.
- Humanity. Let a recognizable person speak. Keep curiosity and judgment where the facts support them.

Apply them together. Brevity must not remove needed context. Simplicity must not weaken precision.

## Hard rules

- No em dashes (`—`), `--`, or spaced hyphens as clause separators. An en dash is valid in numeric and date ranges. Preserve punctuation inside quotations and cited titles.
- No semicolons in articles, reports, plans, or technical docs. Target zero everywhere else.
- Keep explanatory colons rare. Use a colon before a list, code block, quotation, or compact label.
- Sentence length: median 12–17 words, standard deviation under 12, under 20% of sentences below 8 words. Short sentences carry facts, never verdicts.
- Cap rule-of-three lists and "not X, Y" antithesis at 2 per post.
- Open with a constraint, measurement, or concrete bug. Never open with a textbook definition, a scene-setting generality, or "In today's world".
- No TL;DR box, no `## Conclusion`, no closing summary. End when the promise is paid.
- Use sentence case for titles unless the target repository sets another convention (jkomyno.dev leaves titles as authored). Never batch-convert existing titles. Preserve project names.

## Protect the facts

- Paraphrase only claims the input or trusted project context establishes.
- Do not infer ownership, implementation, behavior, measurements, dates, motives, or personal experience.
- Verify consequential claims against a live source when cheap. Verify time-sensitive behavior.
- Keep supplied facts, verified facts, inferences, recommendations, and unknowns separate. Match confidence to the class.
- Use first person only when the source shows Alberto did the work. "We" only for collaborative work.
- Present project code as implementation only after checking it. Label shortened, reconstructed, hypothetical, and pseudocode examples.
- Do not invent prerequisites, verification criteria, recovery actions, quotations, numbers, conflict, or emotional stakes. Mark the gap.
- Preserve titles and quoted material exactly. Do not restyle another person's prose.
- Ask for the smallest missing author-only fact when accuracy depends on it.

## Evidence gate

- A claim about a real system carries a unit, a source, and a comparison.
- Report something that ran: a number, a table, a reproduced failure, or a worked calculation.
- A cited summary of someone else's result is not a post. Cap it at 1,000 words.
- A number from a third party carries a link and the date it was read.

The full gate list is in [rubric.md](references/rubric.md).

## Voice

- Technical choices follow the pattern: what was done, why, the strongest rejected option, the constraint that ruled it out.
- Show failures as evidence: observation, likely cause, changed decision, remaining uncertainty.
- Use concrete nouns, versions, measurements, dates, and constraints. Replace intensity with a number or remove it.
- Keep one exact name per technical concept.
- Active voice. Contractions are fine. Parenthetical asides stay brief.
- Humor is sparing and lands after dense material. Enthusiasm is stated through specifics.
- On personal content (bios, about pages), warmth is welcome and still earned by specifics.
- Do not argue or reassure the reader to make a point. State the fact or mechanism.

## Route the request

| Task | Read |
| --- | --- |
| Any post, report, or thread | [engineering-report.md](references/engineering-report.md) |
| Notes or a partial draft becoming a technical article | [article-workflow.md](references/article-workflow.md) and [clear-technical-english.md](references/clear-technical-english.md) |
| Visitor-facing portfolio content, bios, talk descriptions, project copy | [portfolio-content-evaluation.md](references/portfolio-content-evaluation.md) |
| Voice match is uncertain, or a corpus audit needs examples | [calibration.md](references/calibration.md) |
| Publication review or a quality gate | [rubric.md](references/rubric.md) |
| Short form (tweet, thread, abstract, site description) | This file and the evidence and slop rules in engineering-report.md |

For content published on jkomyno.dev, also load that repository's `editorial-standard` skill, `VOICE.md`, and `BRAND.md`. They add the site's review procedure, figure gates, and MDX mechanics.

Do not apply this skill to commit messages, code identifiers, or third-party quotations. For work communication use `jk-work-writing`.

## Banned phrases and puffery

Never use "Let's dive in", "Let's explore", "Let's unpack", "In today's world", "in the ever-evolving landscape", "It's important to note", "it's worth noting", "delve", "dive into", "This approach offers several key benefits", "In conclusion", "to summarize", or "it could be said that".

Remove unsupported puffery: `production-ready`, `next-generation`, `cutting-edge`, `state-of-the-art`, `robust`, `seamless`, `scalable`, `modern`, `intuitive`, `elegant`, `effortless`, `lightweight`, `comprehensive`, `powerful`, `plug-and-play`. Replace `significantly`, `dramatically`, `vastly`, `incredibly`, `extremely`, and `very` with evidence.

`At its core` and `under the hood` are allowed at most once when they add meaning. The structural slop rules are in engineering-report.md.

## Edit and verify

Run in order.

1. Scan punctuation: `rg -n -- '—|--| - |;' <target>`. Preserve code, URLs, flags, ranges, quotations, and valid list lead-ins.
2. Measure sentences with `python3 -I scripts/sentence-band.py <file>` (see engineering-report.md). Fix a median outside 12–17, an sd of 12 or more, or 20% or more of sentences under 8 words.
3. Trace personal and factual claims to the source. Restore altered titles and quotations.
4. Check the opening, the evidence gate, first person, tense, and technical names.
5. Run the slop pass: banned phrases, verdict-restatement sentences, self-praising transitions, personified quantities, definitional pairs, rhythmic negation, and the cap of 2 on rule-of-three and "not X, Y".
6. Remove sentences that only announce, transition, summarize, or decorate.
7. Apply the routed reference before delivery.

Return finished prose by default. Keep outlines, scores, and editorial scaffolding out of the response unless asked.
