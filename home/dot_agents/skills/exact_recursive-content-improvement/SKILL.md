---
name: recursive-content-improvement
description: Iteratively improves written content for deep-tech portfolios, software engineer personal sites, and tech agency websites. Runs a generate-evaluate-diagnose-improve loop with scored criteria tailored to technical credibility, voice consistency, and audience engagement. Use when writing or editing blog posts, case studies, talk descriptions, project copy, about/bio sections, or any prose destined for a developer portfolio.
---

# Recursive Content Improvement

A self-improvement loop for producing higher-quality prose on deep-tech portfolio sites. Generate, score against explicit criteria, diagnose weaknesses, rewrite, repeat.

**Never ship first-draft content for anything visitor-facing.** Run the loop.

## Quick Start

1. Write or receive the initial draft.
2. Identify the content type (blog post, case study, talk description, project card, about/bio, snippet description).
3. Score every criterion for that type on a 1-10 scale. Be brutal.
4. Diagnose anything below 8/10: what specifically fails, why, and what "passing" looks like.
5. Rewrite the weak sections from scratch — don't patch.
6. Re-score. Repeat until every criterion hits 8/10 minimum.
7. Run adversarial pressure. If it survives, ship it.

## The Loop

```
generate --> evaluate --> diagnose --> improve --> repeat (until passing)
```

### Generate

Create the initial output as normal.

### Evaluate

Score the output against each criterion for the content type (see tables below). Use a 1-10 scale. Be honest — a 6 means "mediocre," not "decent."

### Diagnose

For each criterion below 8/10:
- What specifically is weak?
- Why does it fail?
- What would a passing version look like?

### Improve

Rewrite addressing each diagnosed weakness. Rebuild weak sections — patching produces Frankenstein prose.

### Repeat

Re-evaluate. Keep looping until all criteria pass the 8/10 threshold. Typical iteration count: 2-3 rounds.

## Voice Alignment

All content must match the author's established voice. These principles apply across every content type:

- **First person singular**: "I chose X" — never academic "we" unless genuinely collaborative.
- **Always explain WHY**: every technical choice needs motivation. Pattern: [What] + [Why] + [What was rejected] + [Why rejected].
- **Honest about failures**: name what didn't work and say why. "The results weren't satisfying" beats diplomatic hand-waving.
- **Concrete details**: exact numbers, specific tools, real measurements. "1.75x-2.5x faster" beats "significantly faster."
- **Mixed sentence rhythm**: short declarative statements for impact, longer multi-clause sentences for nuance. The rhythm alternates.
- **Active voice dominant**: passive only when the agent is genuinely irrelevant.
- **Direct and confident**: state positions without excessive hedging.
- **Emphatic words at sentence end**: the most important word goes last.
- **Positive form**: "dishonest" not "not honest"; "he forgot" not "he did not remember."
- **No AI-sounding phrases**: see Anti-Patterns below.

## Criteria by Content Type

### Blog Post (Technical)

| Criterion | What to evaluate |
|-----------|-----------------|
| **Hook strength** | First paragraph earns the second? States the problem concretely? |
| **WHY-driven** | Every technical choice motivated? Rejected alternatives named? |
| **Concrete detail** | Exact versions, measurements, benchmarks? No vague claims? |
| **Progressive disclosure** | Simplest case first, then layers of complexity? |
| **Code quality** | Snippets are minimal, runnable, and carry the argument? |
| **Failure honesty** | Tradeoffs and failures documented openly? |
| **Voice match** | Sounds like the author, not a generic tech blog? |
| **Value density** | Every paragraph earns its place? No padding? |
| **Conclusion strength** | Directly answers the question posed in the intro? Pragmatic takeaways? |

**Adversarial test:** Would a senior engineer who already knows the topic still learn something? Would they trust the author's judgment?

### Case Study

| Criterion | What to evaluate |
|-----------|-----------------|
| **Problem clarity** | Reader understands the challenge in 30 seconds? |
| **Constraint awareness** | Real constraints named? Time, budget, team size, infra limits? |
| **Decision trail** | Key architectural choices explained with WHY? Alternatives discussed? |
| **Measurable outcomes** | Specific numbers for results? Before/after where applicable? |
| **Stack specificity** | Exact tools, versions, and integration points named? |
| **Failure & pivot honesty** | What didn't work and what changed because of it? |
| **Role clarity** | Author's personal contribution distinct from team effort? |
| **Credibility signals** | Details only someone who did the work would know? |

**Adversarial test:** Would a prospective client reading this say "I want this person on my project"? Would a competitor find anything to dispute?

### Talk / Conference Description

| Criterion | What to evaluate |
|-----------|-----------------|
| **Title punch** | Specific enough to set expectations, intriguing enough to click? |
| **Audience signal** | Clear who benefits and what they'll take away? |
| **Novelty claim** | What's new or contrarian about this perspective? |
| **Concreteness** | Names specific techniques, tools, or results — not vague promises? |
| **Length discipline** | Tight — no filler words, every sentence justifies its existence? |
| **Voice match** | Sounds like a real person, not a CFP template? |

**Adversarial test:** Would a conference attendee choose this talk over three competing sessions in the same time slot?

### Project Description (Card / README)

| Criterion | What to evaluate |
|-----------|-----------------|
| **One-line clarity** | Instantly clear what it does and for whom? |
| **Differentiation** | Why this exists when alternatives exist? What's unique? |
| **Technical precision** | Key technical details without jargon soup? |
| **Proof points** | Stars, downloads, adoption, or concrete performance claims? |
| **Scan speed** | Gist absorbed in under 5 seconds? |

**Adversarial test:** Would a developer browsing 20 projects in a list stop and click through?

### About / Bio Section

| Criterion | What to evaluate |
|-----------|-----------------|
| **Identity clarity** | Reader knows what you do and what you're known for in two sentences? |
| **Specificity** | Named companies, tools, results — not generic "passionate developer"? |
| **Credibility arc** | Career trajectory tells a coherent story? |
| **Personality** | Human voice comes through? Not a LinkedIn summary? |
| **Current focus** | Clear what you're working on and available for right now? |

**Adversarial test:** Would someone who's never heard of you understand your value in 10 seconds? Would someone who has heard of you feel accurately represented?

### Code Snippet Description

| Criterion | What to evaluate |
|-----------|-----------------|
| **Problem statement** | Clear what problem this snippet solves? |
| **Minimal example** | Stripped to the essential lines — no boilerplate noise? |
| **Language/tool context** | Runtime, version, and dependencies stated? |
| **Copy-paste ready** | Works if dropped into a matching project without modification? |

**Adversarial test:** Would a developer searching for this exact problem find this useful within 15 seconds?

## Adversarial Pressure

After all criteria pass 8/10, attack the content from hostile perspectives:

- **Skeptical senior engineer:** "Why should I believe this? Show me the numbers. What's the catch?"
- **Distracted scroller:** "Would I stop for this? In 2 seconds, on a phone, at midnight?"
- **Hiring manager evaluating the portfolio:** "Does this person actually know what they're talking about, or is this surface-level?"
- **Competitor:** "How would a rival tear this apart? What's the weakest claim?"

If it survives all four, ship it. If not, iterate.

## Anti-Patterns (Automatic Failures)

Any of these in the output means the criterion scores 0/10 for Voice Match. Remove them before scoring anything else.

- "Let's dive in" / "Let's explore" / "Let's unpack"
- "In today's world" / "In the ever-evolving landscape"
- "It's important to note that" / "It's worth mentioning"
- "This approach offers several key benefits"
- "Leveraging cutting-edge" / "state-of-the-art" as filler
- Starting paragraphs with "So," or "Now,"
- Rhetorical questions as transitions ("But what does this mean for...?")
- Generic superlatives ("extremely powerful", "incredibly efficient", "game-changing")
- Bullet-heavy explanations where prose would work
- "In summary, we've seen that..."
- "Arguably" / "it could be said that"
- "Robust" / "seamless" / "scalable" as buzzwords without substance
- Exclamation marks in technical writing
- Vague performance claims without numbers

## Evaluation Template

Use this structure when running the loop:

```markdown
## Output v1
[Initial generation]

## Evaluation v1
- Hook strength: 6/10 — Opens with context but no tension; reader has no reason to continue.
- WHY-driven: 8/10 — Good on primary choice, missing rejected alternatives.
- Voice match: 5/10 — Too formal, uses "we" throughout.
[... score all criteria for the content type]

## Diagnosis
1. Hook needs a concrete problem statement or surprising claim in the first sentence.
2. Add one rejected alternative with a specific reason for rejection.
3. Replace "we" with "I"; shorten sentences in the opening paragraph.

## Output v2
[Revised version addressing each diagnosed weakness]

## Evaluation v2
[Re-score — continue until all pass 8/10]
```

## When to Use

**Always use for:**
- Blog posts and articles
- Case study narratives
- Talk titles and descriptions
- Project descriptions and READMEs
- About/bio sections
- Landing page copy
- Any prose a visitor reads to evaluate your credibility

**Can skip for:**
- Internal notes and drafts
- Commit messages
- Code comments
- Metadata fields (tags, dates)
- Content that won't be published

## Guidelines

- The loop adds 2-3 iterations on average. That's 5 minutes for content that represents you for years.
- Score honestly. Inflated scores defeat the purpose.
- Diagnose before rewriting. Rewriting without diagnosis repeats the same mistakes.
- Rebuild, don't patch. Splicing fixes into weak prose creates uneven quality.
- When the `jkomyno-writing-style` skill is available, defer to it for voice and style decisions. This skill handles the improvement loop; that skill handles the voice.
