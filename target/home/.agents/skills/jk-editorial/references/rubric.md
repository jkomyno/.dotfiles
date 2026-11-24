# Editorial rubric

This is the jkomyno.dev gate list. It is mirrored at `.agents/skills/editorial-standard/rubric.md` in the `ai-jkomyno-dev` repository. Edit both together. The Figure gates and MDX references apply to that site. The Core, Evidence, and Engineering report gates apply to any public piece.

Each gate is pass or fail, and each is checkable by reading the piece or operating the figure. The source of a gate is marked PS (the PlanetScale post), JS (the Jane Street post), or site (an existing rule of this site).

## Core gates

1. **Backbone.** After the opening and the last section, a reader can state the claim of the piece in one sentence.
2. **Opening.** The first screen shows a concrete artifact, a production pain with its cost, or the prior context and what differs this time. It states the questions that the sections answer. It carries no background preamble. (PS, JS)
3. **First-hand contribution.** The piece contains something that did not exist before the author made it: a measurement, a run of the real system, a derivation, a reproduced failure, or a figure that shows a mechanism. (site)
4. **One cast, one scenario.** Every actor and value has one short name, used identically in prose, code, tables, and figures. One running example carries the piece. (PS)
5. **Reader's vocabulary.** Each term the intended reader may not know is defined in one sentence, at first use, with words that reader already has. One sentence is the budget: the reader is a capable engineer, so do not walk up to an idea over several sentences when two carry it. (site)
6. **Section handoff.** Each section answers the question the previous one left open. Headings are questions or noun phrases, in a flat H2 sequence where the material allows. (PS)
7. **Anticipated objection.** At least once, the piece states the reader's likely wrong instinct or objection, then answers it with the reason. (PS, JS)
8. **Code has a job.** Each code block is introduced by what to notice and followed by what it showed. A toy case comes before the real one. Code the reader should try is a runnable `CodeWindow` with fixed inputs and logged results, never an instruction to open the browser console. (JS, site)
9. **Limits stated.** The piece says plainly where the approach fails, costs more, or stops applying, and gives the reason. (PS, JS)
10. **Ending.** The last section gives a decision rule, a limit, or what the piece does not cover. It does not replay the body. The PlanetScale post ends in a summary. This site does not. (site)
11. **Length is earned.** There is no word target. Every section changes the reader's model, and anything that does not is cut. A cited summary of someone else's result is at most 1,000 words. Original work runs as long as its evidence. (site)
12. **Voice and mechanics.** The piece passes `jk-editorial` (no em dashes, no semicolons, no TL;DR box) and, on jkomyno.dev, `mdx-authoring`. (site)

## Figure gates

Pick the form first. A process over time gets a self-playing stepped animation, ideally SVG and CSS with no hydration. A question where the reader chooses the inputs gets a hydrated explorer with a meaningful default state. A result gets a static chart or a table.

1. **Earns its place.** The figure shows a mechanism, a sequence, or a comparison that prose would need a paragraph of bookkeeping to convey. (site, `PRODUCT.md`)
2. **Reads without interaction.** The first frame, or the loop as it plays, already makes the point. Interaction adds exploration and never carries the main message. (PS)
3. **Steps labeled in the frame.** A process is shown as named steps or cases, such as "STEP 2 OF 5" or "CASE 1 OF 3", each with one sentence that says what changed. (PS)
4. **State in words.** Every state change has a text label inside the figure. Color alone never carries meaning. (PS)
5. **Same cast.** Names and numbers in the figure match the prose and the code exactly. (PS)
6. **Prose around it.** The paragraph before the figure names its steps or cases in the figure's own order and wording. The paragraph after says what to take from it. (PS)
7. **Bounded.** A loop shows every step within about 30 seconds. A stepped widget has at most about seven steps. (PS)
8. **Reduced motion.** Under `prefers-reduced-motion` the figure is a readable static state. (PS, site)
9. **Light and dark.** Both themes are legible and use existing design tokens. (PS, site)
10. **Text alternative.** Alt text or the accessible name narrates the whole sequence, including the end state. A hydrated widget also has an entry in `src/lib/widget-descriptions.ts`. (PS, site)
11. **Keyboard and touch.** Controls work from the keyboard and at 390 px wide. Test touch the way `mdx-authoring` describes. (site)

## Evidence gates

1. **Every number has a home.** Each quantitative claim in the prose maps to a table, a chart, or a stated measurement. (JS)
2. **Self-describing results.** The table or chart itself shows the baseline, the unit, whether lower or higher is better, and the input size. (JS)
3. **Absolute beside relative.** Ratios appear with the absolute values, so the reader can recompute them. (JS)
4. **Named comparison.** The text says what is compared and why those cases were chosen. (JS)
5. **Reproducible setup.** The text gives the commit or version, the runtime version, and for timings the hardware, the number of runs, and how time was taken. The Jane Street post omits hardware and run counts. Do not copy that omission. (site)
6. **Correctness apart from speed.** Correctness evidence is reported separately and names its oracle. (JS)
7. **A negative result.** At least one unflattering result or limit is stated plainly, with its reason. (JS)
8. **Measured apart from believed.** Wording separates what the author measured, what a source says, and what the author expects. (JS)
9. **Results as a progression.** Each step of the argument gets its own table or figure and one sentence of conclusion. (JS)
10. **Attributed third-party numbers.** A number from someone else carries a link and the date it was read. (site)
11. **Claim carries unit, source, and comparison.** A claim about a real system states a unit, where the number came from, and what it was compared with. (site)
12. **Something ran.** The piece reports a number, a table, a reproduced failure, or a worked calculation that was actually produced. A piece with none is a summary and ships only at 1,000 words or fewer. (site)

## Engineering report gates

Apply to posts, reports, and threads. Measure with `scripts/sentence-band.py`.

1. **Opening.** The first paragraph opens with a constraint, a measurement, or a concrete bug. It does not open with a definition of the topic. (site)
2. **Sentence band.** Median sentence length is 12–17 words, the standard deviation is under 12, and under 20% of sentences have fewer than 8 words. Short sentences carry facts, never verdicts. (site)
3. **Anti-slop.** The piece has no verdict-restatement sentences, self-praising transitions, personified quantities, definitional pairs, or balanced negation used for rhythm. (site)
4. **Template cap.** Rule-of-three lists and "not X, Y" antithesis appear at most 2 times combined. (site)
5. **No semicolons.** There are none in the article body. (site)
