# Calibration examples

Read this when the voice match is uncertain or a set of related prose shows repeated templates. Examples 1 to 6 are Alberto's real edits from his own site history (commits `34c64d7` and `470c1e9` in `ai-jkomyno-dev`, August 2026). Example 7 is constructed to show several tells at once and uses placeholder facts.

## Contents

- [Paragraph-level rewrites](#paragraph-level-rewrites)
- [Sentence-level punctuation](#sentence-level-punctuation)
- [Concrete descriptions](#concrete-descriptions)
- [Corpus-level repetition](#corpus-level-repetition)

## Paragraph-level rewrites

### 1. Recap opener replaced by a number and a constraint

Source: the opening of Part 2 of the submodular maximization series.

**Before:**

> In Part 1, I defined submodular functions and showed that they capture the pattern of diminishing returns across sensor placement, document summarization, influence maximization, and many other domains. I formalized the constrained maximization problem: given a monotone submodular function $f$ and a budget $k$, find $\max_{S \subseteq \mathcal{V}} f(S)$ subject to $|S| \leq k$. I also showed that this problem is NP-hard: enumerating all $\binom{n}{k}$ candidate subsets is intractable for any realistic problem size.

**After:**

> With $n = 1{,}000$ candidates and a budget of $k = 50$, there are roughly $10^{85}$ possible subsets to check, more than the estimated number of atoms in the observable universe. Part 1 showed why brute force is off the table: constrained submodular maximization, $\max_{S \subseteq \mathcal{V}} f(S)$ subject to $|S| \leq k$ for a monotone submodular $f$, is NP-hard.

What changed: the opening is now a computed number for a concrete case. The recap of Part 1 shrank to one clause with a link. Three "I" sentences about what the previous post did became zero.

### 2. Generic recap closer deleted

Source: the end of the `createrequire` debugging post.

**Before:**

> ## What I would remember next time
>
> - If a Node builtin behaves strangely inside bundled server code, suspect transformed semantics before you suspect the builtin itself.
> - [two more bullets omitted here]
>
> This bug looked like a Prisma problem, then a Wasm packaging problem, then a broken binary. In the end it was mostly a bundler boundary problem. That is the part I would want to remember.

**After:** the whole section and its closing paragraph are removed. The section before References now ends on the fix shipping in Prisma 6.11.0, with its link.

What changed: the ending is the last fact, not a replay. The closing sentence "That is the part I would want to remember" was a self-praising transition.

### 3. Mic-drop wrap-up deleted

Source: the end of the React Native build-tools post.

**Before:**

> ## Wrapping up
>
> Simple as pie. I personally love when a tedious issue can be fixed in a handful of lines of code. No more manual edits, no more downgrading Gradle, no more repeating yourself after every `yarn install`.

**After:** removed. The post ends on the sentence that explains what the script does: it makes Gradle overwrite `compileSdkVersion` and `buildToolsVersion` in every dependency.

### 4. Semicolon chain split into evidence steps

Source: the sensor coverage example in the submodular series.

**Before:**

> The first sensor might cover 120 $\text{m}^2$ on its own; the second adds 95 $\text{m}^2$ of *new* area; the third adds only 60 $\text{m}^2$.

**After:**

> The first sensor might cover 120 $\text{m}^2$ on its own. The second adds 95 $\text{m}^2$ of *new* area. The third adds only 60 $\text{m}^2$.

What changed: each period marks one step of the sequence. The numbers stay.

### 5. Vague intensity replaced

Source: the Jump Point Search post and the submodular series.

**Before:** "When almost every cell is a jump point, the pruning skips very little."

**After:** "When almost every cell is a jump point, the pruning skips almost nothing."

**Before:** "this lower-bound guarantee holds for the worst-case, so the algorithm may perform significantly better on many practical instances."

**After:** "This lower bound holds in the worst case. On many practical instances, the algorithm performs closer to optimal."

**Before:** "is arguably the most celebrated theorem in submodular optimization."

**After:** "is the most celebrated theorem in submodular optimization."

What changed: the intensifier and the "Note that" lead-in are gone, and the second claim is now a plain statement. The third "after" still lacks a measurement, so it remains a candidate for a source or a number. Removing "arguably" makes the claim stronger, so keep it only when the source supports it.

### 6. Unremarkable instead of "very normal"

**Before:** "At the time I was testing a very normal stack: Next.js 15, default webpack, ESM via `"type": "module"`, …"

**After:** "At the time I was testing an unremarkable stack: Next.js 15, default webpack, ESM via `"type": "module"`, …"

What changed: "very" is gone. The stack list that follows is the evidence, so the sentence stays specific.

### 7. Engineering-report slop, constructed

Placeholder facts. Do not reuse these numbers.

**Before:**

> Latency is the silent killer of user experience. A p99 is a percentile wearing a number's clothes. Our dashboard looked healthy. It was not. The p99 sat at 480 ms while the median sat at 40 ms. That is the whole trick: averages hide tails. Software does not have to crash to tilt reality.

**After:**

> The dashboard showed a median latency of 40 ms. The p99 on the same traffic was 480 ms, which means at least one request in a hundred took twelve times the median or more. The median alone hid the tail.

What changed: the verdict sentences, the personified quantity, the balanced negation, the self-praising transition, and the closing aphorism are deleted. The facts stay, with a unit and a comparison. The last clause explains why the dashboard missed the tail, so it is a cause the author must confirm. The numbers are placeholders.

## Sentence-level punctuation

**Before:** "The first probe passed; the second exposed the stale cache."

**After:** "The first probe passed. The second exposed the stale cache."

The period keeps the evidence sequence clear.

**Before:** "The retry failed for one reason: the worker reused its failed module state."

**After:** "The worker reused its failed module state. That caused the retry to fail."

The rewrite states the cause directly instead of using punctuation as an explanatory hinge.

**Before:** "WebAssembly makes Rust-to-JavaScript integration look easy — until you hit the walls."

**After:** "WebAssembly makes Rust-to-JavaScript integration look easy until you hit the walls."

The clause needs no typographic pause.

Keep a colon when it introduces a real list.

**Before:** "I walked through the real friction points — string conversion, data type mapping, and serialization overhead."

**After:** "I walked through three friction points: string conversion, data type mapping, and serialization overhead."

## Concrete descriptions

**Before:** "A lightweight embedded document database written in Rust with ACID transactions and MVCC support for storing JSON documents locally."

**After:** "Embedded document database in Rust for local JSON storage, with ACID transactions and MVCC."

The rewrite removes the generic opener, unsupported adjective, and filler noun.

**Before:** "Production-ready pnpm monorepo template with tsdown, Turborepo, Vitest, and Biome."

**After:** "pnpm monorepo template with tsdown, Turborepo, Vitest, and Biome."

The technologies already describe the artifact. `Production-ready` adds no evidence.

## Corpus-level repetition

Do not open many talk abstracts with "I showed how" or "I walked through." Choose a verb that matches the work. Examples include `traced`, `built`, `argued`, `unpacked`, `proposed`, and `outlined`.

Do not start several nearby section descriptions with `Selected`. Remove the repeated framing and let each section's subject lead.
