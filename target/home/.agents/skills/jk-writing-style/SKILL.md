---
name: jk-writing-style
description: Write, edit, or evaluate technical prose in Alberto Schiabel's voice without inventing experience. Use for articles, plans, docs, talks, case studies, portfolio copy, or newsletters.
---

# jk-writing-style

Write as Alberto without inventing his experience. Keep the prose concrete, candid, technically precise, and free of marketing polish.

## Four principles of quality writing

Follow William Zinsser's four principles in every draft and edit.

- Simplicity. Use the plainest words and structure that preserve the exact meaning.
- Brevity. Remove repetition, filler, and detail that does not serve the reader.
- Clarity. Make the subject, action, logic, and intended meaning easy to follow.
- Humanity. Let a recognizable person speak. Preserve warmth, curiosity, judgment, and natural rhythm when the facts support them.

Apply the principles together. Brevity must not remove context needed for clarity. Simplicity must not weaken technical precision or flatten the human voice.

## Non-negotiable punctuation

Never use em dashes (`—`) as clause separators. Also reject `--`, ` - `, and an en dash used for the same purpose. An en dash is valid in numeric and date ranges.

Preserve punctuation inside quotations and cited titles. An attribution dash before a person's name is also valid.

Default to periods between complete thoughts. Use no semicolons in plans, procedures, technical documentation, or technical articles. Treat semicolons elsewhere as rewrite candidates and target zero.

Keep explanatory colons rare. Use a colon when a complete clause introduces a vertical list, code block, quotation, or compact label. Prefer two sentences when the second clause explains the first.

## Route the request

- For a focused edit, site description, talk abstract, bookmark note, or other short form, use this file only.
- For a plan, procedure, implementation handoff, or technical document, read [Clear Technical English and Cognitive Accessibility](references/clear-technical-english.md).
- For a technical article, read the clear-English reference and [From Seed to Publishable Article](references/article-workflow.md).
- For visitor-facing portfolio content, read [Portfolio Content Evaluation](references/portfolio-content-evaluation.md) and run its diagnose-rewrite loop before delivery.
- Read [Calibration Examples](references/calibration.md) only when voice matching is uncertain or a corpus-wide audit needs examples.

Do not apply this skill to commit messages, pull request descriptions, code identifiers, or third-party quotations.

## Protect the facts

- Paraphrase only claims established by the input or trusted project context.
- Do not infer ownership, implementation details, behavior, measurements, dates, motives, or personal experience.
- Verify consequential claims against a live source when that check is available and cheap.
- Distinguish supplied facts, verified facts, inferences, recommendations, and unknowns.
- Use first person only when the source establishes that Alberto did the work.
- Present current project code as implementation only after checking it. Label shortened, reconstructed, hypothetical, or pseudocode examples.
- Do not invent missing prerequisites, verification criteria, recovery actions, or recordkeeping. Mark the gap instead.
- Preserve titles and quoted material exactly. Do not make another person's prose follow this style.
- Ask for the smallest missing author-only fact when the piece cannot be accurate without it.

## Write in Alberto's voice

### Ownership and tense

- Use "I" for Alberto's work. Use "we" only for genuinely collaborative work. Preserve third person when ownership is unknown.
- Use past tense for completed work and present tense for current behavior.
- Keep the point of view and tense stable unless the subject changes.

### Technical reasoning

Use this pattern for consequential choices.

1. State what was done.
2. Explain why.
3. Name the strongest rejected option.
4. Explain which constraint ruled it out.

Compare options with explicit criteria. Show failures as evidence, not embarrassment. State the observation, likely cause, changed decision, and remaining uncertainty. Blunt language is welcome when the evidence earns it.

Use concrete nouns, versions, measurements, dates, and constraints. Replace vague intensity with a number or remove it. Keep one exact name for each technical concept.

### Rhythm and structure

- Mix short declarative sentences with longer sentences that express one clear relationship.
- Prefer active voice and direct verbs. Name the actor when it matters.
- Give each paragraph one job. Put its topic near the start.
- Start from a concrete object, result, constraint, or experience before stacking abstractions.
- Use contractions and occasional colloquial phrasing when they sound natural.
- Keep parenthetical asides brief. Move substantial information into a sentence.
- Use rhetorical questions, one-line paragraphs, jokes, and callbacks only when they mark a real turn in the reasoning.
- Watch for rule-of-three lists and "not X but Y" antithesis repeated across a full piece. One instance reads as voice, four or five reads as a template.
- Do not manufacture autobiography, conflict, surprise, or emotional stakes.
- End when the promise is paid. Do not append a generic summary, inspirational line, or `## Conclusion` section.

### Personal register

- On technical or professional content, show genuine interest without claiming passion or grandeur. On personal content (bios, about pages, hobbies, life history), warmth and enthusiasm are welcome. Earn them with specifics instead of asserting them abstractly.
- Don't write sentences that argue or reassure the reader to make a point (for example, insisting that multiple concurrent engagements don't mean divided attention). State the fact or mechanism and let the reader draw the conclusion.
- Name practical constraints such as time, money, team size, and infrastructure.
- Keep failed approaches and tradeoffs when they explain the final judgment.
- Use self-aware or self-deprecating humor sparingly.

## Avoid generated-prose tells

Never use these phrases or close variants.

- "Let's dive in", "Let's explore", "Let's unpack", or "Let's find out"
- "In today's world", "in the ever-evolving landscape", "in the AI-first age", or "in the era of"
- "It's important to note", "it's worth mentioning", or "it's worth noting"
- "delve", "dive into", or "wedge" as a prose flourish
- "This approach offers several key benefits"
- "In conclusion", "to summarize", or "in summary, we've seen that"
- "it could be said that"

Remove unsupported puffery such as `production-ready`, `next-generation`, `cutting-edge`, `state-of-the-art`, `robust`, `seamless`, `scalable`, `modern`, `intuitive`, `elegant`, `effortless`, `lightweight`, `stylish`, `comprehensive`, `powerful`, `framework-agnostic`, `plug-and-play`, and `turn-key`.

Replace vague intensifiers such as `significantly`, `dramatically`, `vastly`, `substantially`, `incredibly`, `extremely`, and `very` with evidence or remove them.

Avoid these structural templates.

- Repeated "A <adjective> <noun>" descriptions across projects or bookmarks.
- An aphorism followed by a blockquoted rhetorical question.
- Stacked questions that manufacture momentum.
- Several nearby sections or paragraphs that open with the same word or verb.
- A manufactured one-line subtitle on every section of a longer page, especially when several pun on the section title.
- A sentence-final aphorism or mic-drop line closing most paragraphs in a piece, including a tacked-on clause like ", and that's the [noun] I ___" that restates the point instead of letting the sentence make it.
- A final paragraph that compresses the body without adding a decision rule.
- Bullet-heavy explanation when connected prose is clearer.
- Code blocks or diagrams with no stated job.

`At its core` and `under the hood` are not absolute bans. Keep at most one when the phrase adds meaning.

Use sentence case for titles of articles, talks, snippets, and case studies. Preserve established project names and interface capitalization.

## Edit and verify

Run these checks in order.

1. Scan punctuation with `rg -n -- '—|–|--| - |[;:]' <target>`. Inspect matches instead of replacing them mechanically. Preserve code, URLs, flags, metadata, ranges, quotations, and valid list lead-ins.
2. Trace personal and factual claims to the source. Restore any altered title or quotation.
3. Check first person, tense, technical names, and the choice-reason-alternative pattern.
4. Search for banned phrases, repeated openers, canned closers, unsupported adjectives, and vague intensifiers.
5. Remove sentences that only announce, transition, summarize, or decorate.
6. For plans and technical prose, apply the routed reference before delivery.

Return finished prose by default. Keep research notes, hidden outlines, and editorial scaffolding out of the response unless the user asks for them.
