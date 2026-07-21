# From Seed to Publishable Article

Use this workflow when the input is rough notes, a few prompted sentences, a transcript, or an incomplete draft and the requested output is a complete article. Keep the author's facts and point of view intact while supplying editorial structure, research, explanation, and polish.

## Contents

1. Choose the editorial mode
2. Establish the article contract
3. Build the evidence packet
4. Choose the article shape
5. Draft in two directions
6. Write the article
7. Run the editorial passes
8. Apply the publication gate
9. Calibrate the output

## 1. Choose the editorial mode

Infer the lightest mode that satisfies the request:

- **Preserve:** Correct and sharpen prose without adding new claims or changing the structure.
- **Develop:** Turn notes into an outline or partial draft while keeping open questions visible.
- **Expand:** Turn a small seed into a complete article, including research and examples.
- **Reshape:** Rebuild an existing draft around a clearer argument, even if most sentences change.
- **Review:** Diagnose truth, structure, voice, and publication readiness before rewriting.

Default to **Expand** when the user supplies a few sentences and asks for an article. Do not make a short idea long merely to resemble an article. A 700-word argument can be complete; a difficult mental model may need 4,000 words.

## 2. Establish the article contract

Extract an internal contract before writing:

- **Seed:** What did the author actually say, observe, build, or believe?
- **Reader:** Who should understand or care about this?
- **Backbone:** What single sentence should the reader be able to repeat accurately?
- **Tension:** What is confusing, costly, surprising, disputed, or unresolved?
- **Change:** What should the reader understand, decide, or do differently afterward?
- **Proof:** Which example, measurement, source, or experience makes the backbone credible?
- **Boundaries:** What does the article deliberately not claim?

Write the backbone as a defensible sentence, not a topic label. "Web Workers" is a topic. "A retry only refetches a failed runtime when it creates a new worker with a fresh module map" is a backbone.

Separate the seed into four buckets:

1. Supplied facts
2. Author opinions or interpretations
3. Facts that can be verified
4. Personal details only the author can supply

Never invent first-person experience, motives, conversations, results, dates, numbers, or emotions. Research verifiable gaps. Ask one focused question when a missing personal fact or choice would materially change the article's backbone. Otherwise, make the narrowest defensible assumption.

## 3. Build the evidence packet

Collect only the evidence the backbone needs:

- Prefer source code, specifications, official documentation, original research, release notes, and first-party statements.
- Verify time-sensitive claims against the current source of truth.
- Reproduce technical behavior when the claim depends on a runtime, build, package, or browser.
- Test code examples when practical. Mark illustrative pseudocode as pseudocode.
- Compare consequential seed claims with the live implementation when available. Treat a conflict as an editorial issue to resolve, not a reason to preserve a stale statement.
- Use exact source code when presenting a project implementation. Label shortened, reconstructed, and hypothetical snippets so readers do not mistake them for verbatim code.
- Record the rejected explanation when it helps the reader understand why the accepted one is stronger.
- Keep opinion, inference, and measured fact distinguishable in the prose.

Do not turn research notes into a literature dump. Each citation must support a sentence the argument needs. Cut facts that do not alter the reader's model or decision.

## 4. Choose the article shape

Match the seed to a dominant shape. Combine shapes only when the transition is useful.

| Primary arc | Useful sequence |
| --- | --- |
| Narrative reversal | Plausible action, confidence, consequence, re-evaluation, principle |
| Progressive construction | Smallest example, one complication, failed attempt, revised model, next complication |
| Symmetric argument | Strongest case for A, strongest case for B, incompatibility, synthesis or conditional decision |
| Forensic audit | Verdict, mechanism, repeated real cases, affected groups, remedies, policy |
| Taxonomy or map | Define the world, name its parts, connect them, mark omissions |
| Principles | Observed problem, principles with consequences, boundary cases, transfer question |
| Compressed reflection | Overlooked contrast, accumulated examples, named consequence, imperative |
| Chronological memoir | Time spine, concrete episodes, present-day qualification, returned motif |

Prefer one central conflict over a catalogue of facts. If two ideas need different backbones, split them into separate articles.

## 5. Draft in two directions

### Top-down: make the route visible

Create a rough outline that includes:

1. The concrete situation that creates tension
2. The concepts the reader needs before the central insight
3. The example or argument that delivers the main realization
4. The limits, tradeoffs, or counterargument
5. The consequence that resolves the opening tension

Treat the outline as disposable. Reorder concepts when one section depends on knowledge introduced later. Delete sections that are interesting but do not support the backbone.

Use section headings as signposts in the argument. Prefer headings that name the question, object, or shift. Avoid generic headings such as "Background", "Benefits", "Deep Dive", and "Conclusion" when a more specific heading exists.

### Bottom-up: prove the central explanation

Draft the hardest or highest-value passage first. This is usually:

- the smallest example that makes the mental model click;
- the reproduction that eliminates a plausible cause;
- the comparison that makes a design choice defensible;
- the scene where the author's belief changed.

Ask whether this passage would justify the article by itself. If it remains muddy, reduce the scope, improve the example, or gather better evidence before writing the surrounding prose.

Reconcile the outline with the central passage. Expect to discard much of the first outline after finding the clearest route from not knowing to knowing.

## 6. Write the article

### Open on something the reader can hold

Begin with a concrete object, result, scene, bug, code fragment, or disputed claim. Establish the subject, tension, and likely payoff early. Do not warm up with industry-scale context or announce that the topic is important.

Good openings often do one of these:

- show a small thing behaving unexpectedly;
- state a precise claim that appears to contradict common advice;
- place the author at the moment a decision or assumption failed;
- give the reader a tiny example they can predict before the explanation.

Avoid stacking rhetorical questions merely to create momentum. One real question can organize an article. A compact list can also work when it names the reader's actual problems and the body answers each one.

### Use rhetorical craft when the structure earns it

Keep expressive techniques available, but make each one do a job:

- Use a rhetorical pivot such as a short question at a genuine hinge in the argument, then answer it before it becomes a mannerism.
- Use a pop-culture callback when it supplies a useful model, shared reference, or satisfying bookend. Explain the technical point without requiring the reader to know the reference.
- Isolate a one-line paragraph when the preceding prose has built enough pressure for the line to change the reader's interpretation.
- Repeat a phrase deliberately when the repetition marks progression or pays off earlier setup.

Judge these devices by placement, not by a fixed quota. Keep them when removing them flattens the argument; cut or vary them when they merely advertise a style.

### Teach from concrete to abstract

Introduce the smallest useful example before naming the general model. Let the reader predict what happens, show the result, then explain it. Add complexity one constraint at a time.

For a long tutorial or reference-heavy guide, consider an answer-first route: give the working answer, minimal example, or compact map near the beginning, then derive it for readers who need the model. Do this only when the early answer can stand without creating a dangerous half-understanding.

Define niche terms on first use. Use the same name for the same concept throughout. If the existing vocabulary hides the problem, name the missing distinction and demonstrate why it matters.

Use analogies to preserve a relationship, not to decorate a paragraph. State where an analogy stops matching when the mismatch could mislead the reader.

### Make each section earn the next

Give each section one job:

1. Answer the question created by the previous section.
2. Supply evidence or an example.
3. Expose the next necessary question, constraint, or consequence.

Keep causal links explicit. "This changed the build" is weak. "Excluding the package from prebundling kept its `import.meta.url` asset paths inside Vite's worker graph" gives the reader a mechanism.

Vary paragraph length, but use one-sentence paragraphs only for genuine turns. Vary sentence length inside substantial paragraphs. Let technical density accumulate, then give the reader a short sentence that lands the point.

### Show the rejected route

Include alternatives when they sharpen the decision. State why a reasonable person would choose each alternative, then name the constraint that rules it out here. Do not build straw men or imply that one local decision is universal advice.

For failed attempts, preserve the sequence of evidence. The reader should see how the author changed their mind, not merely receive the winning answer.

### End when the promise is paid

Return to the opening tension and resolve it. End with one of:

- a direct, conditional recommendation;
- the consequence of the mental model;
- a changed belief grounded in the story;
- the next experiment or unresolved boundary.

Do not append a compressed replay of every section. A mini-book may earn a retrieval-oriented recap when it restores named principles and gives the reader a decision rule. Do not add a generic inspiration line. Once the central question has a satisfying answer, stop.

## 7. Run the editorial passes

Run separate passes. Trying to solve all of them sentence by sentence preserves weak structure.

### Pass 1: Authorship and truth

- Trace every personal claim to the seed or the author's confirmed input.
- Verify factual and time-sensitive claims, including consequential claims supplied in the seed when a live source is available.
- Remove invented certainty, numbers, causality, and quotations.
- Label a hypothesis or inference as such.
- Compare every project-code block with the current source or label it as shortened, reconstructed, hypothetical, or pseudocode.

### Pass 2: Argument

- State the backbone after reading the draft. If it changed, revise the contract.
- Make every section support, test, qualify, or apply that backbone.
- Remove side quests and duplicated explanations.
- Strengthen the best counterargument before answering it.
- Confirm that one primary arc still governs the article.

### Pass 3: Reader model

- Check every prerequisite at its first use.
- Move definitions and examples before the conclusions that depend on them.
- Replace abstraction stacks with one concrete case.
- For each difficult mechanism, use a value substitution, event sequence, state transition, call trace, before-and-after output, or minimal reproduction.
- Give each code block, diagram, table, or story beat a role: baseline, prediction, failure, change, validation, or transfer.

### Pass 4: Alberto's voice

- Restore first-person ownership where the author did the work.
- Explain why each consequential choice was made.
- Prefer exact nouns, versions, measurements, and constraints.
- Keep uncertainty and failed attempts when they are honest and useful.
- Remove marketing language, unearned drama, and mannerisms that repeat without purpose.

### Pass 5: Rhythm and compression

- Read the opening, first sentence of each section, and ending as one continuous argument.
- Vary sentence and paragraph lengths without creating a pattern.
- Replace throat-clearing with the claim it delays.
- Cut sentences whose removal changes nothing.
- Keep a short paragraph only when its isolation adds real weight.
- Read the full piece aloud and vary any cadence that repeats accidentally.

### Pass 6: Mechanical scan

Run the `jk-writing-style` diagnostic pass for em dashes, banned phrases, repeated openers, closer templates, verb tics, citation damage, and ESL-shaped phrasing.

### Pass 7: Publication surface

- Choose a title that names the real object or tension without clickbait.
- Use a subtitle only when it adds information the title cannot carry.
- Check links, citations, code formatting, image alt text, and frontmatter.
- Match the repository's component and code-block conventions.
- Preview the rendered article when the publishing format supports it.

## 8. Apply the publication gate

Call an article ready only when all of these are true:

- A reader can state the backbone in one sentence.
- The opening creates the question the body actually answers.
- Every factual claim is supplied, verified, or clearly qualified.
- No first-person detail was manufactured.
- The central example works and appears before avoidable abstraction.
- Each section advances the argument.
- Alternatives are represented fairly.
- The ending resolves the opening without summarizing the article.
- The prose passes the `jk-writing-style` diagnostic scan.
- The rendered artifact follows the target publication's conventions.

If a blocking fact is missing, do not disguise a draft as publication-ready. Ask for the smallest missing input or present the exact verification still required.

## 9. Calibrate the output

For a seed-to-article request, return the publishable article by default. Keep research notes, internal contracts, and discarded outlines out of the final prose unless the user asks to see the editorial process.

When useful, provide a compact handoff after the article with:

- claims that still need the author's confirmation;
- assets or examples that would materially improve it;
- title alternatives that reflect genuinely different emphases.

Do not bury an incomplete article under a long explanation of how it was produced.

### Example calibration

Seed:

> We moved a WebAssembly runtime from a CDN into Vite's worker graph. Retrying initialization started working, but only after we recreated the worker. ES-format workers and a prebundle exclusion were also required.

Possible backbone:

> Local bundling makes browser-runtime retries reliable only when a fresh worker can resolve the runtime's assets again.

Useful route:

1. Reproduce the failed CDN retry.
2. Show why reusing a worker also reuses its failed module state.
3. Recreate the worker and observe the new fetch.
4. Explain why ES workers preserve dynamic imports and `import.meta.url` asset resolution.
5. Explain why prebundling relocates those assets.
6. End with the exact conditions under which local bundling improves reliability.

Do not invent why the team attempted the migration, how long it took, or what users reported. Those details must come from the author.
