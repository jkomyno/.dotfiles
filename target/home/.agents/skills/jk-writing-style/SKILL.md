---
name: jk-writing-style
description: Writes, expands, edits, and reviews public-facing prose in Alberto Schiabel's (@jkomyno) voice. Use when turning rough notes or a few prompted sentences into a publishable technical article, or when writing and polishing blog posts, conference talk abstracts, case studies, project descriptions, bookmark notes, site copy, or newsletters that should sound like Alberto.
---

# jk-writing-style

Alberto's voice, distilled from his blog posts, talks, design docs, master's thesis, and the audit of his portfolio site. Apply this skill when writing or editing prose that should read as his.

## The one rule above all others

**Never use em dashes (`—`).** They are the single most obvious AI tell. Use a period, comma, colon, semicolon, or parentheses instead, depending on the relationship between the clauses.

Surrogate dashes are the same offense: `--` (double hyphen), ` - ` (space-hyphen-space mid-clause), `–` (en dash) standing in for a clause separator. The only legitimate use of `–` is inside numeric or date ranges (`2022–2024`, `pp. 1–14`).

**Legitimate exceptions:**
- Em dashes inside cited paper titles, song lyrics, or direct quotes from external sources. Do not edit other people's prose to match this rule.
- Attribution dashes before a name at the end of a testimonial or pull-quote (`— Name, Year`). Traditional typographic convention, not the AI-prose dash.

## Scope

Applies to:
- Blog posts, technical articles, newsletter issues
- Conference talk abstracts and speaker bios
- Case studies, project descriptions, bookmark notes
- Site copy: hero taglines, About page, section descriptions, CTAs
- LinkedIn posts and X threads on professional topics

Does NOT apply to:
- Commit messages and PR descriptions (their own conventions)
- Code comments and identifiers
- Internal Slack DMs
- Quoted material from third parties

## Quick start

1. **Never em dashes.** See rule above.
2. **First person "I" when ownership is established**, not academic "we", unless the work was genuinely collaborative.
3. **Always explain WHY**, not just what. Every choice needs motivation.
4. **Concrete over abstract.** Numbers, names, versions, and dates beat "significantly", "many", or "modern".
5. **Honest about failures.** Name what didn't work and why.
6. **No marketing voice.** Strip puffery and superlatives; let substance carry.
7. **Vary openers and verbs across multi-piece content.** Repetition reads as a template.
8. **Preserve factual boundaries.** Never invent ownership, behavior, implementation details, measurements, dates, motives, or first-person experience. Research verifiable gaps or ask for the smallest missing fact.

## Route the request

- For rough notes, a transcript, or a few sentences that must become a complete article, read [From Seed to Publishable Article](references/article-workflow.md). Then read only the relevant sections of [Technical Article Craft Patterns](references/technical-article-craft.md): opening and arc for structure; explanations, artifacts, and analogies for teaching; pacing for rhythm; uncertainty and endings for final editing. Return the publishable article by default, not the hidden editorial scaffolding.
- For an existing article with structural problems, follow the same route before rewriting.
- For a focused prose edit, site description, talk abstract, or other short form, stay in this file and run the diagnostic pass. Do not load long-form references unless the request needs them.
- Preserve Alberto's voice as the identity layer. Use the corpus-derived reference as a craft layer: narrative tension, progressive explanation, rhetorical timing, callbacks, and endings.

## Factual integrity

- For a rewrite, paraphrase only the claims the input already makes. Do not infer ownership or a technology's role from its name. If the draft says a project uses Monaco and a Web Worker, do not add what either component does unless the repository or user supplied that fact.
- For an expansion, separate supplied facts from verifiable facts, interpretations, and author-only details. Research verifiable gaps; ask for author-only details that the article needs.
- For publication-ready technical prose, verify consequential seed claims against the live source when that check is available and cheap. If the seed conflicts with the current source, surface the conflict and use the current behavior or ask which historical state the article should describe.
- Use first person only when the input or trusted project context establishes that Alberto did the work. Voice does not grant permission to turn a third-person description into autobiography.
- Qualify an inference as an inference when it materially helps. Never present a plausible inference as observed behavior.
- Use exact, current project code when a block is presented as implementation. Label reconstructed, shortened, or hypothetical code explicitly; never make invented code look copied from the project.

## Diagnostic pass (when editing existing prose)

In this order:

1. **Dash scan.** Run `rg -n -- '—|–|--| - ' <target>` to find candidates. In prose, replace em dashes and use en dashes only for numeric or date ranges. Treat `--` and ` - ` matches as candidates to inspect, not automatic edits: preserve code spans and fences, URLs, CLI flags, frontmatter, metadata, and quoted material.
2. **Banlist scan.** Search for the banned phrases below; flag every hit.
3. **Opener-template scan.** Bookmarks or projects opening with "A &lt;adjective&gt; &lt;noun&gt;…". Blog posts opening with aphorism plus `>` rhetorical question. Section descriptions starting with the same word three or more times in close proximity.
4. **Closer-template scan.** Final paragraph beginning "Across all these…", "Every one of…", "In conclusion", or otherwise restating the body in compressed form. Cut the paragraph if it adds nothing.
5. **Verb-tic scan.** Across a multi-document set (e.g., 19 talk abstracts), how often does the same opening verb repeat? Aim for no more than twice in a corpus of ten.
6. **Voice consistency.** First-person throughout? Tense consistent within a piece? "I" not "we" unless team-collaborative?
7. **Citation guard.** Did any em-dash edit accidentally step on a paper title or quoted source? Restore those.

## The voice

### Person and tense
- Default to "I" for professional writing when the work belongs to Alberto. "We" only when the work was genuinely collaborative. Preserve third person when ownership is unknown.
- Past tense for completed work ("I traced", "I built"); present for current state ("currently building", "now ships").
- Don't switch within a piece without reason.

### Sentence construction
- Mix punchy and longer sentences. Short declaratives for key points. Longer multi-clause sentences for nuance and tradeoffs. The rhythm alternates: a crisp statement, then elaboration.
- Use semicolons to join closely related ideas instead of two flat sentences.
- Imperative voice for actionable advice ("Always profile first.", "Don't pick X under the guise of Y.").
- Colloquial expressions sparingly for emphasis. They land hardest after dense technical prose.
- Minimize parenthetical asides. Restructure into separate sentences or subordinate clauses. Use parentheses only when the aside is genuinely minor.
- "i.e." and "e.g." are fine but sparse. Prefer "that is" or "for example" when the sentence is already dense.
- Put statements in positive form: "dishonest" beats "not honest"; "he forgot" beats "he did not remember".
- Place emphatic words at the end of the sentence. The reader's attention lands there. "Because of its hardness, this steel is used for making razors" beats "This steel is used for making razors because of its hardness."
- Parallel construction for co-ordinate ideas. Similar content takes similar form.
- Trim wordy constructions: "the fact that" → "since/because"; "the question as to whether" → "whether"; "he is a man who" → "he".
- Clean, grammatically correct English. No ESL artifacts. The voice comes from structure and reasoning, not grammatical quirks.

### Paragraph structure
- Give the reader something concrete to hold before stacking abstractions. A scene, code fragment, result, or precise constraint can provide the context.
- Prefer substantial paragraphs of 3 to 6 sentences, but isolate one sentence when it marks a real turn, reveal, or payoff. Avoid turning the whole article into a drumbeat of dramatic fragments.
- Natural transitions. No "Let us now turn to" or "Moving on,".

### Storytelling and rhetorical devices
- Build curiosity from a real gap in the reader's model. Show a result, let the reader form a prediction, then expose the missing distinction.
- Use a rhetorical question at a genuine hinge. Answer it soon enough that it advances the argument. Several consecutive questions usually imitate momentum instead.
- Use a pop-culture reference, joke, or playful callback when it clarifies the model or rewards earlier setup. Make the technical point understandable without knowing the reference.
- Repeat a phrase or sentence shape when the repetition marks progression. Vary it when it becomes a template.
- Let an article argue both sides when each side is genuinely compelling. The eventual synthesis will feel earned because the reader has seen the strongest case for each.
- Bring an opening object, phrase, or image back near the end when it gains a new meaning. Do not force a callback onto an article that already has a cleaner ending.
- Explain abstract behavior operationally. Substitute concrete values, trace calls or events, show a state transition, or reproduce the before-and-after output.

### Explaining technical choices (the most distinctive trait)

Pattern: [What was done] + [Why] + [What was considered but rejected] + [Why it was rejected].

Examples from the corpus:
- "I chose Prim's algorithm over Kruskal's because it's more suitable when the graph is represented as a distance matrix."
- "I dropped this approach after noticing much worse runtime performance without any improvement in solution quality."

Companion patterns:
- **Concession-then-rebuttal** for persuasive arguments. Acknowledge the opposing view's validity before explaining why your position is stronger. "X's viewpoint isn't wrong. But there's so much more to Y than Z."
- **Historical context as motivation.** Explain the evolution that led to the current problem. "This representation used to be X, but we had to Y, leading to Z."
- **Progressive disclosure.** Introduce the simplest version first, then complicate.

### Honesty about failures
- Name failed approaches explicitly rather than glossing over them.
- "The results weren't particularly satisfying."
- "This approach was both slower and slightly worse than the fixed rate determined by calibration."
- Call things "useless" when they are.
- Discuss tradeoffs with genuine uncertainty.
- Blunt assessments: "This is messy, and feels too 'magical'" beats diplomatic euphemism.

### Persuasive technical arguments
- Lead with concession.
- Reframe the question. "The value proposition is X, not Y" often rescues a stuck argument.
- Stack evidence: multiple specific examples per claim, each adding a new angle.
- Self-aware meta-commentary sparingly: "which is rich coming from me, since I believe X".
- End with an imperative only when the evidence supports a general instruction. Otherwise give conditional advice tied to explicit constraints.

### Conclusions and recommendations
- Directly answer questions posed earlier; restate them and give concrete answers.
- Pragmatic recommendations with conditions: "If the instance size isn't excessive and the same pattern must be applied to several batches, it might be worth letting CPLEX run for a few hours."
- List possible improvements with concrete specifics, not vague hand-waving.
- Honest cost/benefit: "implementing the metaheuristic required about 12 times the time needed for the exact algorithm."
- **Do not add a generic summary paragraph that restates the body.** If you finished making the argument in the previous section, stop. A mini-book or reference-heavy guide may earn a retrieval-oriented recap when it restores named principles and adds a decision rule. "Across all of these examples..." style endings remain one of the strongest signals of AI-generated prose. Also no "## Conclusion" or "## Wrapping up" headings.

### Personal and reflective register
- Specific and concrete: names, dates, places, exact circumstances.
- Compare options with clear criteria before stating the choice.
- Genuine enthusiasm without overselling. "Given my interest in genetic algorithms" beats "I'm deeply passionate about".
- Discuss practical constraints honestly: time, money, team size, infrastructure limits.
- Self-deprecating humor sparingly for personality: "I personally like Serialized Schema more, but having 'SS' as an acronym would be unfortunate."

## Banlist

### Phrases (never use)
- "Let's dive in" / "Let's explore" / "Let's unpack" / "Let's find out"
- "In today's world" / "In the ever-evolving landscape" / "In the AI-first age" / "In the era of" / "In the age of"
- "It's important to note" / "It's worth mentioning" / "It's worth noting"
- "delve", "delves", or "delved" / "dive into" (overused by Claude in particular)
- "wedge", "wedges", or "wedged"
- "at its core" / "under the hood" (occasional use OK; if it appears three times in a piece, cut two)
- "This approach offers several key benefits"
- "In conclusion" / "To summarize" / "In summary, we've seen that"
- "Leverage" / "Leveraging" as a verb (almost always replaceable with "use" or "with")
- "Arguably" / "It could be said that" (hedging)

### Marketing puffery (strip on sight)
- production-ready, next-generation, cutting-edge, state-of-the-art
- robust, seamless, scalable, modern, intuitive, elegant, effortless
- lightweight, stylish, comprehensive, powerful
- framework-agnostic, plug-and-play, turn-key
- "blazingly fast" / "lightning fast"

### Vague intensifiers (replace with a number or cut)
- significantly, dramatically, vastly, substantially, considerably
- incredibly, extremely, very, truly
- "much faster" / "much smaller" → use a ratio
- "miles easier" / "way better" → state the actual difference

### Opener templates (vary or rewrite)
- "A &lt;soft adjective&gt; &lt;noun&gt;…" for project, bookmark, or snippet descriptions. The auto-LLM repo-summary template.
- "An interactive…" / "An accessible…" / "A practical…" / "A comprehensive…" / "A hands-on…" / "A deep dive…" / "A guide to…". All flavors of the same template.
- Three or more section descriptions in close proximity opening with the same word (e.g., "Selected …").
- One-sentence aphorism followed by a `>` block-quote rhetorical question. Works once; reads as template across multiple posts in the same series.
- Stacked rhetorical questions used as canned momentum ("How does X work? How does Y work? How does Z work? Let's find out."). A compact question list is useful when it inventories the reader's real problems and the article actually answers them.

### Closer templates (cut)
- A "## Conclusion" or "## Wrapping up" heading on a blog post that's already made its argument.
- A final paragraph that begins "Across all these examples…", "Every one of these…", "In short…", or otherwise compresses the body.
- A "Simple as pie" / "Hope this helps" / "And there you have it" sign-off.

### Punctuation tics
- Em dashes (see rule above).
- Exclamation marks in technical writing. Personal asides on a personal blog: rare, intentional, never two in a row.
- Rhetorical questions that manufacture a transition or arrive in stacks. Keep a question that names the article's real puzzle or turns the argument at the right moment.

### Structural tells
- Bullet-point-heavy explanations where prose would do. Bullets are useful for symmetric comparisons, glossaries, decision criteria, and retrieval-oriented recaps.
- Code blocks with no surrounding prose explaining why.
- Buzzwords without substance ("robust" without a number, "scalable" without a load).
- Same verb opening multiple paragraphs or items in a series ("I showed…", "I showed…", "I showed…").

## Transition words

**Preferred:**
- "However," for primary contrast.
- "In particular," for drilling into specifics.
- "Moreover," for adding support.
- "This meant that" / "The consequence was" for cause and effect.
- "Even though" for concessive clauses.
- "For instance," for examples.
- "But there's so much more to X than Y." for pivoting from a conceded point.

**Avoid:**
- "Additionally" → use "Moreover" or "In addition".
- "Importantly" / "Notably" → use "In particular" or just state the thing.
- "It is worth noting that" → never.
- "Furthermore" → too stiff. "Moreover" or "Beyond that" works.

## Formatting conventions

- Code and tool names in monospace: `CPLEX`, `C++17`, `std::vector`.
- Tables for quantitative comparisons with precise numbers.
- Inline technical notation when it aids clarity.
- Links as references, not decoration.
- Code examples: minimal case first, then full-featured version.
- Diff-based code examples when the reader needs to change existing code.
- Stability and versioning precision: "Minor releases can introduce additional fields, but they cannot remove any existing field" beats "the API is mostly stable".
- Content titles (blog posts, snippets, talks, case studies) use sentence case, not Title Case — see `CLAUDE.md`'s "Adding Content > Title Casing" in the jkomyno-dev repo for the exact rule and known exceptions. Project names and site UI copy keep their existing Title Case convention.

## Before/after pairs (from real edits)

These are real fixes from a 2026 audit of jkomyno.dev. Use them as calibration.

### Em dashes

**Before:** "WebAssembly makes Rust-to-JavaScript integration look easy — until you hit the walls."
**After:** "WebAssembly makes Rust-to-JavaScript integration look easy until you hit the walls."
**Why:** The em dash here is a soft pause; the sentence reads cleaner without it.

**Before:** "Edge runtimes promise low latency, but they strip away most of Node.js — including the database drivers your ORM depends on."
**After:** "Edge runtimes promise low latency, but they strip away most of Node.js, including the database drivers your ORM depends on."
**Why:** When the dash sets off a parenthetical extension, a comma does the same work.

**Before:** "I walked through the real friction points — string conversion, Rust-to-JavaScript data type mapping, and the serialization overhead most tutorials ignore."
**After:** "I unpacked the real friction points: string conversion, Rust-to-JavaScript data type mapping, and the serialization overhead most tutorials ignore."
**Why:** When the dash introduces a list, a colon is the standard punctuation.

### Bookmark "A &lt;adjective&gt; &lt;noun&gt;…" template

**Before:** "A fast package manager for macOS and Linux written in Zig that uses Homebrew's bottles and formulas under the hood, with native .deb support for Docker containers."
**After:** "Zig package manager for macOS and Linux that reuses Homebrew's existing bottles and formulas, with native .deb support for Docker containers."
**Why:** Drop the "A fast" opener and let the technical specifics carry. "Reuses" replaces "uses... under the hood" which carried no information.

**Before:** "A lightweight embedded document database written in Rust with ACID transactions and MVCC support for storing JSON documents locally."
**After:** "Embedded document database in Rust for local JSON storage, with ACID transactions and MVCC."
**Why:** "Lightweight" is on the banlist. "MVCC support" becomes "MVCC"; the "support" suffix is filler.

### Marketing puffery

**Before:** "I build developer tools for the AI-first age. 10+ years across Prisma, Composio, and more."
**After:** "I build developer tools at Composio and Prisma. TypeScript, Rust, WebAssembly. 10+ years in open source."
**Why:** "AI-first age" is banlist filler. The original implied "10+ years at those companies" which is false; the rewrite keeps the defensible career statistic.

**Before:** "Production-ready pnpm monorepo template with tsdown, turborepo, vitest, and Biome."
**After:** "pnpm monorepo template with tsdown, turborepo, vitest, and Biome."
**Why:** "Production-ready" is empty marketing; the rest of the sentence is already factually descriptive.

### Verb tic across a corpus

**Before (across 13 talk abstracts):** "I showed how…" / "I walked through the…"
**After (per-talk verb match):** "I traced…" (teardown of a library), "I built…" (construction), "I argued that…" (thesis), "I unpacked…" (hidden complexity), "I broke down…" (from-X-to-Y progression), "I proposed…" (alternative path), "I outlined why…" (case for adoption).
**Why:** The same verb across a corpus reads as a template. Picking the verb that matches what each talk actually did improves variety and accuracy at once.

### Repeated section openers

**Before** (four section descriptions on the homepage):
- "Selected open-source tools, investigations, or enterprise platforms I've built."
- "Selected roles in developer tooling, AI infrastructure, and open source."
- "Selected languages, frameworks, and tools I reach for when building."
- "Selected blog posts and technical articles…"

**After:**
- "Open-source tools, investigations, and enterprise platforms I've built."
- "Roles in developer tooling, AI infrastructure, and open source."
- "Languages, frameworks, and tools I reach for when building."
- "Blog posts and technical articles on what I'm working on or learning."

**Why:** Four section descriptions opening with the same word in close visual proximity read as templated. Variety restores the impression of hand-written copy.

### Colon-fragment grammar

**Before:** "The thread connecting all I've done is: I followed what I found interesting and challenging at the time."
**After:** "One thread runs through everything I've done: I followed what I found interesting and challenging at the time."
**Why:** "The thread...is:" treats a sentence fragment as the predicate. Rephrasing puts a complete clause before the colon.

### ESL phrasing

**Before:** "It was my first, chaotic experience in a remote startup, at a time when I didn't think having a daily office job plus university to study was enough."
**After:** "It was my first chaotic experience in a remote startup, at a time when I didn't think working full-time on top of university was enough."
**Why:** "Having a daily office job plus university to study" is an ESL-shaped noun phrase that drops a native-English equivalent. The fix also removes the stray comma between "first" and "chaotic".

**Before:** "...combinatorial and probabilistic methods optimization."
**After:** "...combinatorial and probabilistic optimization methods."
**Why:** Inverted noun-phrase order. The modifier ("combinatorial and probabilistic") attaches to "methods", not "optimization".
