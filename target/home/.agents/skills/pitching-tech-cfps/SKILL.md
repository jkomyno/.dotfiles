---
name: pitching-tech-cfps
description: Generates compelling tech conference CFP (Call for Papers) proposals that get accepted. Crafts talk titles, abstracts, outlines, speaker bios, and notes to organizers tailored to specific conferences. Use when the user wants to submit a talk proposal, write a CFP, prepare a conference submission, or pitch a tech talk idea.
---

# Pitching Tech Conference CFPs

Generate compelling Call for Papers (CFP) proposals that stand out from hundreds of submissions and get your talk accepted at tech conferences.

## Quick Start

Ask the user for:
1. **Conference name and URL** (to tailor the proposal)
2. **Talk idea** (topic, angle, or problem being solved)
3. **Speaker background** (relevant experience, unique perspective)

Then generate a complete CFP submission package.

## Understanding CFP Platforms

Most tech conferences use one of these platforms:

**Sessionize** fields:
- Session title (required)
- Session description (required)
- Session format (lightning, talk, workshop)
- Track/topic category
- Audience level (beginner, intermediate, advanced)
- Speaker name, email, tagline, biography
- Custom fields per conference

**PaperCall** fields:
- Talk title
- Elevator pitch (short summary)
- Talk description / abstract
- Notes to organizers (private)
- Session format
- Audience level
- Tags / topics

**Custom forms** (Google Forms, Airtable, etc.) vary but typically ask for a subset of the above.

## The CFP Submission Package

Generate all of the following components for each proposal:

### 1. Talk Title

Craft a title that is:
- **Specific and descriptive** over clever or punny
- **Problem-oriented** — frames what the audience gains
- **Concise** — under 80 characters
- **Memorable** — stands out scanning a conference schedule

Good examples:
- "K8s at Lightspeed: Managing 1000 Clusters in 60 Seconds"
- "Type-Safe Database Queries Without an ORM"
- "From 12s to 200ms: A Real-World Performance Debugging Story"

Bad examples:
- "Scaling Kubernetes" (too vague)
- "My Journey with React" (self-focused, not audience-focused)
- "Things I Learned" (says nothing)

### 2. Abstract / Description (150-400 words)

This is the public-facing blurb attendees see. It must accomplish three things:

**a) Hook with a real problem (1-2 sentences)**
Open with a concrete pain point the audience recognizes. Use a scenario, a statistic, or a provocative question.

**b) Promise specific outcomes (2-3 sentences)**
State exactly what attendees will learn or be able to do after the talk. Use active verbs: "build," "implement," "debug," "evaluate" — not "learn about" or "gain insights."

**c) Establish credibility through specifics (1-2 sentences)**
Mention concrete technologies, scale numbers, or real results. Show domain depth without being a sales pitch.

**d) Leave them wanting more (1 sentence)**
End with an inviting forward look or a hint at surprising findings.

Structure template:
```
[Problem hook — why should anyone care?]

[What you'll cover — be specific about topics and techniques]

[What attendees walk away with — concrete, actionable outcomes]

[Credibility signal — why you're the right person / why now]
```

### 3. Elevator Pitch (1-2 sentences, ~300 characters)

A punchy summary for quick scanning. Formula:
```
[Audience] will learn [specific skill/insight] by [approach/angle], enabling them to [concrete outcome].
```

### 4. Talk Outline (private, for organizers)

Provide a structured breakdown showing you've thought through the talk:

```
- Introduction & problem framing (3 min)
- [Section 1: Context/Background] (5 min)
- [Section 2: Core technique/solution] (8 min)
- [Section 3: Demo / case study] (7 min)
- Key takeaways & resources (2 min)
```

Adjust timing to match the session format (lightning: 5-10 min, talk: 25-45 min, workshop: 60-120 min).

### 5. Notes to Organizers (private)

This is your chance to speak candidly to the selection committee. Include:
- **Why this talk matters now** for their specific audience
- **Your unique qualification** — what experience or perspective makes you the right speaker
- **Prior speaking experience** (if any) with links to recordings
- **Anything else relevant** — first-time speaker willingness to do a dry run, flexibility on format, etc.

Keep it under 200 words. Be genuine, not boastful.

### 6. Speaker Bio (50-100 words)

Write in third person. Include:
- Current role and company
- Relevant domain expertise
- One humanizing detail (hobby, community involvement, etc.)
- No more than 2 sentences of credentials

### 7. Audience Level Recommendation

Classify as one of:
- **Beginner** — No prior knowledge needed; introductory concepts
- **Intermediate** — Assumes working knowledge of the domain
- **Advanced** — Deep dive requiring significant prior experience

Justify the classification briefly.

## Tailoring to the Conference

Before writing, research and consider:
- **Conference themes and tracks** — align your proposal to announced topics
- **Past speakers and talks** — differentiate from what's been covered
- **Audience profile** — startup developers vs enterprise architects vs students
- **Conference values** — some prioritize diversity, first-time speakers, open source, practical content
- **Blind review** — if the CFP is anonymized, avoid identifying information in the abstract and description; put personal details only in speaker fields

## What Reviewers Actually Evaluate

Reviewers read hundreds of proposals. They assess:

1. **Relevance** — Does it fit the conference topics and audience?
2. **Clarity** — Can they immediately understand what the talk is about?
3. **Specificity** — Are concrete outcomes promised, not vague "insights"?
4. **Novelty** — Does it offer something attendees can't just Google?
5. **Speaker fit** — Is there evidence this person can deliver on the topic?
6. **Audience value** — Will attendees walk away with actionable knowledge?

## Proposal Enhancement Strategies

After drafting, improve the proposal by:

- **Cut filler words** — remove "very," "really," "just," "actually," "I think"
- **Replace passive voice** — "Patterns will be explored" becomes "You'll implement three patterns"
- **Add numbers** — "We reduced latency" becomes "We reduced p99 latency from 12s to 200ms"
- **Check the "so what?" test** — every sentence should pass "why would an attendee care?"
- **Read it as a reviewer** — imagine reading it as proposal #187 of 300 at 11pm

## Multi-Submission Strategy

Maximize acceptance chances:

- Submit 3-5 proposals per conference (quality over quantity)
- Vary formats: one talk, one lightning talk, one workshop
- Cover different tracks if the conference has multiple
- Reuse and adapt proposals across conferences — but always tailor the abstract to each audience
- Track submissions in a spreadsheet with deadlines, statuses, and notes

## Guidelines

- Never include sales pitches, product marketing, or company promotion in proposals
- Focus on what the audience learns, not what the speaker knows
- Use second person ("you'll learn") in abstracts, third person in bios
- Avoid jargon unless the audience is explicitly technical
- If the conference has a code of conduct, ensure the proposal aligns with it
- For blind review CFPs, keep all identifying information out of the abstract and outline
- Offer to generate multiple proposal variants so the user can pick the strongest

## Workflow

1. Gather context: conference details, talk idea, speaker background
2. Research the conference (themes, tracks, audience, past talks)
3. Draft the full submission package (all 7 components above)
4. Review against the "What Reviewers Evaluate" checklist
5. Suggest improvements and alternatives
6. If the user wants, generate 2-3 title/abstract variants to choose from

For detailed examples of accepted and rejected proposals, see [examples.md](examples.md).
