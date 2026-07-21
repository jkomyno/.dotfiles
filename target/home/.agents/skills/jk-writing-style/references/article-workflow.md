# From Seed to Publishable Article

Use this workflow when rough notes, a transcript, or a partial draft must become a complete technical article. Return the article by default. Keep contracts, evidence notes, and discarded outlines hidden unless the user asks for them.

Apply the methods through Alberto's voice and actual evidence. Do not imitate a recognizable author, copy distinctive phrases, or force every article into the same structure.

## Contents

- [Set the contract](#1-set-the-contract)
- [Build the evidence packet](#2-build-the-evidence-packet)
- [Choose the tension and arc](#3-choose-the-tension-and-arc)
- [Draft from both directions](#4-draft-from-both-directions)
- [Build the explanation](#5-build-the-explanation)
- [Write the article](#6-write-the-article)
- [Run the editorial passes](#7-run-the-editorial-passes)
- [Apply the publication gate](#8-apply-the-publication-gate)

## 1. Set the contract

Write a hidden contract before drafting.

- Identify the intended reader and what they already know.
- State the article's promise in one sentence.
- State the backbone claim the evidence can support.
- Name non-goals and author-only facts that remain missing.
- Choose the evidence that can change the reader's model.
- Decide what the reader should understand or do at the end.

Narrow the promise when the evidence cannot support it. Do not compensate with confidence or invented experience.

## 2. Build the evidence packet

Separate material into four groups.

| Group | Treatment |
| --- | --- |
| Supplied | Preserve the source's factual boundaries |
| Verified | Record the live source and relevant version or date |
| Inferred | Qualify the explanation and retain plausible alternatives |
| Missing | Ask for an author-only fact or name the unresolved verification |

Classify consequential claims as observed, inferred, recommended, or speculative. Match confidence to the class. Verify time-sensitive behavior and every project-code block that is presented as current implementation.

Do not invent decisions, mistakes, conversations, measurements, motives, or emotional stakes.

## 3. Choose the tension and arc

A topic names a subject. A tension gives the article motion. Prefer a real contradiction, recurring question, failed prediction, costly tradeoff, or decision that breaks a common rule.

Choose one primary arc.

| Arc | Shape | Best fit |
| --- | --- | --- |
| Narrative reversal | action, consequence, revised judgment | A real mistake changed the author's view |
| Progressive construction | smallest case, complication, failed attempt, revised model | A mechanism must be derived |
| Symmetric argument | strongest case for each option, incompatibility, synthesis | Both approaches have legitimate strengths |
| Forensic audit | verdict, mechanism, cases, effects, remedies | A systemic failure has inspectable evidence |
| Taxonomy | define the world, name its parts, connect them, mark omissions | Readers lack stable vocabulary |
| Principles | observed problems, shared model, consequences, boundaries | Several decisions share a deeper cause |

The opening must preview the proof. Enter a real scene for a mistake, show a small artifact for a constructive explanation, or state the claim for a documented critique. Make the central tension visible within the first few paragraphs.

## 4. Draft from both directions

Use a top-down pass to define the claim, reader value, model change, evidence, and arc.

Use a bottom-up pass to build the hardest section first. Work out the code, trace, measurement, example, or counterargument before polishing the outline.

Let the evidence revise the contract. Narrow the thesis when the concrete section cannot support it. Restructure when the evidence exposes a better question. Optimize for one memorable model, not maximum coverage.

## 5. Build the explanation

For each difficult concept, use this loop.

1. Establish the current model.
2. Let the reader make a prediction.
3. Show the observation or failure.
4. Change one assumption.
5. Name the revised model.
6. Test it on a nearby case.

Keep names, examples, and unrelated variables stable while adding one complication at a time. Derive an abstraction after a concrete case when possible. Explain the mechanism before its consequences.

Give every code block, diagram, measurement, trace, or anecdote a job. It must establish a baseline, enable a prediction, expose a failure, isolate a change, validate the model, or transfer the model to another case. Cut decorative artifacts.

Use an analogy only when its structure predicts something useful. Identify what maps to what and where the mapping stops. Add an exit sentence that returns to the real system.

## 6. Write the article

Give each section one job. It should answer the previous question, supply evidence, and expose the next necessary question or consequence.

Explain consequential choices with Alberto's core pattern. State what was done, why it fit, which reasonable option was rejected, and which constraint ruled it out. Preserve the evidence sequence for failed attempts so the reader can see the judgment change.

Represent counterarguments strongly enough to change the recommendation under different constraints. Put human consequences beside the mechanism that causes them. Do not add a generic people paragraph.

Use rhetorical questions, one-line beats, callbacks, and cultural references only when they mark a genuine change in the model. The technical point must remain understandable without the flourish.

End by resolving the opening tension. Give a conditional rule, changed belief, final test, precise implication, or unresolved boundary. Stop once the promise is paid.

## 7. Run the editorial passes

Run separate passes so sentence polishing does not preserve a weak structure.

### Truth and authorship

- Trace personal claims to the seed or confirmed input.
- Verify consequential and time-sensitive claims.
- Label hypotheses, reconstructions, shortened code, and pseudocode.
- Remove invented certainty, causality, numbers, and quotations.

### Argument and reader model

- Make every section support, test, qualify, or apply the backbone.
- Remove side paths and duplicated explanations.
- Put prerequisites, definitions, and examples before dependent conclusions.
- Confirm that artifacts have a job and counterarguments can affect the result.

### Voice and compression

- Restore justified first-person ownership and reasons for each major choice.
- Keep useful failures, uncertainty, measurements, and constraints.
- Apply [Clear Technical English and Cognitive Accessibility](clear-technical-english.md).
- Remove marketing language, unearned drama, throat-clearing, and sentences whose deletion changes nothing.
- Run the main skill's punctuation, banlist, template, citation, and repetition checks.

### Publication surface

- Use a title that names the real object or tension without clickbait.
- Check links, citations, code formatting, image alt text, and frontmatter.
- Follow the target repository's component and code-block conventions.
- Preview the rendered article when the format supports it.

## 8. Apply the publication gate

Call the article ready only when all conditions hold.

- The opening creates the question the body answers.
- A reader can state the backbone in one sentence.
- Every consequential claim is supplied, verified, or qualified.
- No first-person detail was manufactured.
- The central example works and precedes avoidable abstraction.
- Every section advances the argument.
- Alternatives are represented fairly.
- The ending resolves the opening without replaying the article.
- The prose passes the main diagnostic and clear-English checks.
- The rendered artifact follows the publication's conventions.

If a blocking fact is missing, ask for the smallest missing input or state the exact verification still required. Do not disguise an incomplete draft as publication-ready.
