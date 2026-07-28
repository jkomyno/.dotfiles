# Clear Technical English and Cognitive Accessibility

Use this reference for plans, procedures, implementation handoffs, technical documentation, and technical articles. Apply it with the main skill's punctuation and factual-integrity rules.

The rules adapt several standards and accessibility resources. They do not establish ISO, ASD-STE100, WCAG, legal, or accessibility conformance. Preserve technical meaning and factual accuracy above mechanical compliance.

## Standards map

| Source | Adopted contribution | Boundary |
| --- | --- | --- |
| ISO 24495-1:2023 | Make information relevant, findable, understandable, and usable | The public abstract does not contain the full normative guidelines |
| Plain Writing Act of 2010 | Write clear, concise, well-organized text for the intended reader | The Act governs covered US federal documents, not Alberto's writing |
| ASD-STE100 Issue 9 | Control vocabulary, sentence structure, instructions, warnings, and information flow | Apply as a strong preference, not claimed conformance |
| W3C COGA | Reduce memory demands and make purpose, sequence, and recovery clear | The Working Group Note supplements WCAG and does not establish WCAG conformance |
| JAN guidance | Use written instructions, checklists, short task units, and explicit expectations where useful | Accommodation needs differ between people |
| `i-have-adhd` | Put the request first, separate required work from context, and make completion visible | Transfer writing practices only, not its LLM interaction contract |

## Make the content usable

- Identify the reader, purpose, and task before drafting.
- Put the answer, result, or next executable action first.
- Use descriptive headings and a predictable order. Add a short route map only for a long document.
- Keep required information on the critical path. Move optional detail into a named branch or later section.
- State prerequisites, decisions, consequences, expected results, and verification where the reader needs them.
- End an incomplete handoff with one concrete next action.

## Control the language

- Use common, literal words and direct verbs. Remove throat-clearing and decorative abstraction.
- Give each sentence one primary topic. Make cause, contrast, sequence, and result explicit.
- Prefer active voice. Use passive voice when the actor is unknown or would be inaccurate.
- Use the official technical name for a concept. Do not rotate synonyms for variety.
- Expand a necessary acronym on first use. Remove definitions for terms that disappear from the final text.
- Replace ambiguous pronouns with exact nouns. Check bare uses of `this` and unclear uses of `with`.
- Avoid Latin abbreviations. Write `for example`, `that is`, or the exact remaining items.
- Use neutral, non-discriminatory language.

Keep an instruction at 20 words or fewer when practical. Keep a descriptive technical sentence at 25 words or fewer when practical. Treat both limits as editing thresholds, not reasons to remove necessary grammar or detail.

Give each paragraph one topic and no more than six sentences. Start with a sentence that exposes the paragraph's job. Repeat exact terms when repetition reduces memory load.

## Write plans and procedures

1. Put a prerequisite or condition before the action that depends on it.
2. Give one instruction in each sentence and usually one action in each step.
3. Use the imperative. Name the command, path, value, or artifact precisely.
4. State the observable result and how the reader verifies it.
5. Put optional work outside the required sequence.

Never put more than five actions in one flat numbered sequence. Group a longer supplied sequence into named phases. Do not split one supplied action into imagined substeps.

Do not require readers to remember a value or choice from an earlier section. Repeat the minimum needed to continue. Use an if-then table when several conditions change the route.

For a failure, state what happened, what remains safe, how to recover, and how to verify recovery. If the source omits recovery, mark it as missing and stop before an unsupported retry.

Do not invent commands, paths, owners, metrics, thresholds, test cases, success criteria, recovery actions, or recordkeeping. Preserve a high-level check when the source gives no lower-level method. Mark an unknown as unresolved. Treat an unexplained acronym, unused definition, circular recovery step, or unidentified earlier section as a blocking defect.

## Preserve narrative flexibility

Apply the procedure rules strictly to actionable steps. Use the language rules as strong defaults in technical articles.

Do not force narrative prose into maintenance-manual syntax. Keep contractions, longer sentences, phrasal verbs, and expressive rhythm when they remain clear and sound like Alberto. Do not simplify an official term or alter technical meaning.

## Sources

- [ISO 24495-1:2023 public abstract](https://www.iso.org/standard/78907.html)
- [Plain Writing Act of 2010](https://www.govinfo.gov/content/pkg/PLAW-111publ274/html/PLAW-111publ274.htm)
- [W3C Making Content Usable for People with Cognitive and Learning Disabilities](https://www.w3.org/TR/coga-usable/)
- JAN guidance for [ADHD](https://askjan.org/disabilities/Attention-Deficit-Hyperactivity-Disorder-AD-HD.cfm), [written instructions](https://askjan.org/solutions/Written-Instructions.cfm), and [checklists](https://askjan.org/solutions/Checklists.cfm)
- [Communication standards overview](https://pbs.twimg.com/media/HNt7agKakAAuhGT?format=jpg&name=large)
- [`i-have-adhd` communication skill](https://github.com/ayghri/i-have-adhd/blob/0241185d6c7f2d0763a988ce52eceb13ea9f5c1f/skills/i-have-adhd/SKILL.md)

The ASD-STE100 adaptation comes from Issue 9 rules 1.8–1.11, 2.1–2.2, 3.5–3.7, 4.1–4.5, 5.1–5.5, 6.1–6.6, 8.1–8.3, 9.1, 9.3–9.4, and general recommendations 1–7.
