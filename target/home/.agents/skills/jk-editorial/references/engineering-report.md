# Engineering report register

Use this for blog posts, engineering reports, case studies, social threads, and talk scripts. The anchors are the Hornet post "Big graphs, small vectors: HNSW at a billion" and the Thinking Machines technical notes.

What the anchors share, read for this skill:

- Hornet opens on the problem's scale ("Scaling it to billions of vectors is a hard systems problem"), then lists the criteria a solution had to meet. Numbers carry units. Synthetic examples are marked as illustrations. Charts are labeled "to scale". Tradeoffs are stated with their costs.
- Thinking Machines ("Defeating Nondeterminism in LLM Inference") names the common explanation, says what is right about it, then tests it with a counterexample and refines it. Code and worked numeric examples let the reader check each claim.

Copy the discipline. Do not copy phrasing, structure, or their openings word for word. Alberto's openings start with the artifact, not a principle.

## Contents

- [Open with a constraint, measurement, or bug](#open-with-a-constraint-measurement-or-bug)
- [Sentence-length band](#sentence-length-band)
- [Anti-slop rules](#anti-slop-rules)
- [Evidence gate](#evidence-gate)
- [Positive exemplars](#positive-exemplars)
- [Negative examples](#negative-examples)

## Open with a constraint, measurement, or bug

The first paragraph gives the reader one of these.

- A constraint: what had to hold, and what made it hard.
- A measurement: a number with a unit and a comparison.
- A concrete bug: the file, the line, the wrong behavior.

It also says what the post will show. It carries no definition of the topic, no history of the field, and no scene-setting about how important the topic is.

Test: delete the first paragraph. If the second paragraph reads as the real start, the first was preamble.

## Sentence-length band

Targets for a full article or report, measured over prose only (exclude code, tables, headings, frontmatter, and quotations).

| Metric | Target |
| --- | --- |
| Median sentence length | 12–17 words |
| Standard deviation | under 12 words |
| Sentences under 8 words | under 20% |

Short sentences carry facts. "None of us had written a GPU kernel before October 27." is a fact. "That is the whole trick." is a verdict and is deleted.

A sentence over 30 words is a candidate for splitting, not a violation, when it states one relationship. Do not split a sentence into dramatic fragments to hit the band.

Check a Markdown or MDX file with the bundled script. It strips frontmatter, code, headings, tables, and link targets, so treat the numbers as approximate.

```bash
python3 -I scripts/sentence-band.py <post.mdx>
```

Run it from the skill directory or use its absolute path. A pass does not make prose good. A fail means look at the sentences.

For reference, `my-agents-emulated-the-gpu.mdx` measures at median 15, sd 10.8, 12% under 8 words, and zero semicolons with this script.

## Anti-slop rules

Delete or rewrite each of these.

1. **Verdict-restatement sentences.** A sentence that restates the preceding finding as a moral. "Software does not have to crash to tilt reality." Keep the finding, drop the moral.
2. **Self-praising transitions.** A sentence that tells the reader the point was clever or central. "That is the whole trick." "Here is where it gets interesting."
3. **Personified quantities.** A number or variable doing human things. "A percentile wearing a number's clothes." Say what the quantity is and what it measures.
4. **Definitional pairs.** Two back-to-back sentences that define and then redefine. "A cache is a store of results. It keeps answers close to where they are asked." Keep one, or none if the reader knows the term.
5. **Balanced negation for rhythm.** A rhythmic "X. Not Y." or "It looks reasonable. It is not." pair that withholds the fact for effect. State the fact and the evidence.
6. **Rule-of-three and "not X, Y" antithesis.** At most 2 combined per post. One reads as voice. Four reads as a template.
7. **Punch-then-qualify.** Do not stage a bold line followed by a qualifier. Put the claim with its qualifier and evidence in one sentence.
8. **Analogy meta-commentary.** Do not praise an analogy ("the parallel runs deeper than it looks"). Show the mapping, say where it stops, and return to the real system.
9. **Mic-drop closers.** A sentence-final aphorism closing most paragraphs.
10. **Stacked rhetorical questions** that manufacture momentum.
11. **Section subtitles** on every section, especially punning ones.
12. **Repeated openers.** Nearby paragraphs or sections starting with the same word or verb.
13. **Generic closers.** A final paragraph that compresses the body without adding a decision rule. A `## Conclusion` heading.

Semicolons are banned in articles. A semicolon usually joins two sentences that deserve a period, or hides an unexamined causal link. Write the link.

## Evidence gate

A piece fails when any of these is missing.

- **Unit, source, comparison.** A claim about a real system carries a unit, where the number came from, and what it was compared with. "Latency dropped" fails. "p99 fell from 480 ms to 190 ms on the same 10k-request trace" passes.
- **Something that ran.** The piece reports a number, a table, a reproduced failure, or a worked calculation that the author or an agent actually produced.
- **Summary cap.** A cited explanation of someone else's result is a summary. A summary is at most 1,000 words. A longer piece needs its own run.
- **Measured apart from believed.** Wording separates what was measured, what a source says, and what is expected.
- **Setup named.** Version or commit, runtime, hardware, run count, and how time was taken, for timings.
- **Third-party numbers** carry a link and the date they were read.
- **Illustrations are labeled.** A synthetic or simplified example says so.

Agent-produced results are written impersonally ("Here are both algorithms on a seeded instance") unless the source establishes that Alberto ran them.

## Positive exemplars

These are Alberto's published prose. They show the register and measure inside the band.

**Opening on a measurement and a constraint** (from `my-agents-emulated-the-gpu.mdx`):

> On November 5, 2026 at 08:00 UTC, the kernel track of the Open Kernel Challenge closed. My team finished at overall rank 244 of 2,014. The team was me plus a swarm of coding agents. None of us had written a GPU kernel before October 27, and for the first week our only GPU was the contest's rate-limited judge, so the agents emulated the H200 on a laptop and spent $29.39 of free credit on a real one in the last three days.

Why it works: the first sentence is a dated event. The second is a rank with its denominator. The constraint (no kernel experience, one rate-limited GPU) arrives with numbers, and the short sentences are facts.

**Opening on a concrete bug** (from the TSP solver post):

> I reopened `sampling.h` from my old university TSP project because I expected a concrete case study. Lines 155 to 188 gave me a better article: line 156 cites the correct paper as a bare URL, line 174 computes the paper's random keys, and line 178 builds a priority queue that keeps the wrong end.

Why it works: a file, line numbers, and the exact defect. The reader can open the file and check.

**A fact that explains why the bug survived** (same post):

> A deterministic bug often produces a stable wrong answer. A probability bug keeps producing plausible answers with the wrong frequencies.

Why it works: the contrast is the mechanism, stated once, and it is the reason the bug is hard to see. It is not a verdict on the author's code.

**A comparison that locates a gap** (from the GPU post):

> Read side by side, the two records locate the gap, and it was not correctness. The largest difference I can point to is a GPU of their own, where two versions of a kernel could be timed against each other.

Why it works: the claim is scoped ("the largest difference I can point to") and names the mechanism.

## Negative examples

Each pair shows a sentence that the rules delete and a replacement. The replacements are templates, so fill them with real facts.

| Slop | Problem | Replacement |
| --- | --- | --- |
| "Software does not have to crash to tilt reality." | Verdict restating the finding | Delete. The sentence before it already reported the wrong output. |
| "That is the whole trick." | Self-praising transition | Delete. Start the next paragraph with its first fact. |
| "A p99 is a percentile wearing a number's clothes." | Personified quantity | "p99 is the latency that 99% of requests beat." Then use it with a value and a unit. |
| "A cache is a store of results. It keeps answers close." | Definitional pair | Keep one clause, or drop both if the audience knows caches. |
| "It looks reasonable. It is not." | Balanced negation for rhythm | "The output passes the schema check and has the wrong key order for 3 of 40 inputs." |
| "The fix was simple. The bug was not." | Rhythmic antithesis | "The fix was one line. Finding it took two days of bisecting." (only if both are true) |
| "Fast, simple, and reliable." | Unsupported rule of three | Name the measurement for each, or keep the one that has a number. |
