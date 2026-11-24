# Work formats

Templates and rules for each format. Drop any field the input does not support. Never fill a field with a guess. Write `unknown` or `unassigned` instead.

## Contents

- [Linear update](#linear-update)
- [Slack message](#slack-message)
- [PR description](#pr-description)
- [RFC or design note](#rfc-or-design-note)
- [Incident summary](#incident-summary)
- [Status update and handoff](#status-update-and-handoff)

## Linear update

Target: 60–120 words. The reader skims the issue timeline and needs the state in one pass.

```text
Status: <on track | at risk | blocked | done>. <One sentence: what is true now.>

Done: <what shipped or was verified, with link or evidence>
Blocked: <what, by whom or what, since when>. Needs: <the exact ask>.
Decision needed: <question> by <date>. Recommendation: <option and reason>.
Next: <one concrete action>, <owner>, <date if known>.
```

Rules:

- The first line is the status. Do not open with "Update:" or "Quick update".
- Evidence is a link, a number, or a command result. "Mostly working" is not evidence.
- State `Blocked` only for a real dependency. Name the person or system.
- Omit `Decision needed` and `Blocked` lines when empty. Do not write "None".
- Risk gets one line: what could slip, and what signal would show it.
- Do not restate the issue description.

## Slack message

Target: one screen, usually 1–5 sentences.

- First sentence: the answer, the ask, or the news. Put the ask before the context.
- An ask names who and by when: "@name, can you approve X by Thursday?"
- Skip the greeting line. Start with the content.
- Give a thread reply the answer to the question asked. Add context only if it changes the reader's next action.
- Use a short list only for parallel items (three failing checks, two options). No headers.
- Link evidence (PR, run, dashboard) instead of pasting it. Paste a short error or number inline when it saves a click.
- One message, one topic. Split unrelated asks.
- Do not use "just", "quick question", "sorry to bother", or "per my last message".
- Send the best-guess answer with its uncertainty marked, not a request for permission to look into it.

Shape for an ask:

```text
<Ask in one sentence>, by <when>.
<Why it matters or what it unblocks, one sentence.>
<Link or evidence.>
```

Shape for news:

```text
<What happened or changed.> <Impact on the reader.> <Action needed, or "No action needed.">
```

## PR description

Lead with what changed. Reviewers decide in the first lines whether to read on.

```text
## What
<One to three sentences: the change, in behavior terms.>

## Why
<The problem or constraint. Link the issue or incident.>

## Evidence
<Tests run and their results, before/after numbers with units, a reproduced failure now fixed, screenshots. Paste the command.>

## Risk
<What could break, blast radius, rollback path.>

## Review focus
<Files or decisions where review matters most. Say what is mechanical and can be skimmed.>

## Not in this PR
<Deliberate omissions and follow-ups. Include only real ones.>
```

Rules:

- Describe behavior, not a file-by-file diff narration. The diff shows files.
- Evidence is what was run. Do not claim "tested" without the command or result. If nothing was run, say `Not tested: <what>`.
- Before/after numbers carry units, input size, and the comparison basis.
- Name the strongest rejected alternative and the constraint that ruled it out when the design choice is non-obvious. One sentence.
- Breaking changes, migrations, and config changes go in `What` with an explicit `Breaking:` or `Migration:` line.
- Omit sections that have nothing real to say. A one-line fix can be a two-line PR body.
- Do not write "This PR…" openers, praise of the approach, or a closing summary.
- Keep the title in the repository's convention (for example Conventional Commits). Do not invent a ticket ID.

## RFC or design note

```text
Decision needed: <the question>, by <date>, from <who>.
Recommendation: <option> because <constraint or evidence>.

Context: <only what the reader needs to judge the options>
Options:
- A: <what> | Cost: <> | Rules out: <>
- B: <what> | Cost: <> | Rules out: <>
Why not B: <the constraint that decides it>
Risks and unknowns: <what could make this wrong, and how we would find out>
Rollout: <steps, owners, reversal path>
```

Rules:

- State the recommendation before the analysis.
- Compare options on the same criteria. Name the strongest rejected option.
- Separate measured facts from estimates and from assumptions. Label each.
- Mark open questions as open, with an owner if known.

## Incident summary

```text
Impact: <who or what was affected, how badly, from <time> to <time> (UTC)>
Status: <ongoing | mitigated | resolved>
Cause: <confirmed cause, or "under investigation". Label inference.>
Fix: <what restored service, who or what applied it>
Timeline: <time (UTC): event, one per line, only confirmed events>
Follow-ups: <action, owner, ticket>
```

Rules:

- Facts first, blame never. Describe system behavior and decisions, not people's failings.
- A timeline entry needs a source (log, alert, message). Drop entries nobody can source.
- Do not state a root cause that has not been confirmed. Write `Likely cause (unconfirmed)`.
- Do not invent follow-ups. List what was agreed and mark the rest as proposals.

## Status update and handoff

```text
State: <where the work is, in one sentence>
Done: <verified results with evidence>
Decisions made: <decision and reason>
Open: <unresolved question or risk, with owner>
Next action: <the single first thing the next person does>
Context to load: <links to PR, issue, files, commands>
```

Rules:

- Separate what is done and verified from what is believed done.
- Give the next person one concrete first action, then supporting context.
- Include the exact command, path, or link needed to resume. Do not make the reader search.
- Mark unknowns and unverified assumptions explicitly.

## Before and after

Each example lists the facts the author supplied. The rewrite uses only those.

Slack. Supplied: `cache.test.ts` fails about 1 in 5 CI runs, eviction order is suspected and unconfirmed, next step is rerunning with eviction logging, update promised by Friday.

> Hey! Just wanted to give a quick heads up that I've been looking into the flaky test situation and it seems like it might possibly be related to the cache stuff, will keep digging and let you know!

> `cache.test.ts` fails about 1 in 5 CI runs. I suspect cache eviction order but haven't confirmed it. Next: rerun with eviction logging. Update by Friday.

Linear. Supplied: 41 of 48 tables migrated with matching row counts, 7 composite-key tables fail the import, schema review from a named reviewer pending since Tuesday.

> Made good progress on the migration this week, things are mostly working, a few edge cases left. Will wrap up soon.

> Status: at risk. 41 of 48 tables migrated, row counts match on all 41. 7 tables with composite keys fail the import (error in thread). Blocked: schema review from @name, since Tuesday. Next: migrate the 7 tables once the review lands.

If the real input has no numbers, the rewrite has no numbers. Ask for them or write `unknown`.
