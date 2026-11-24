---
name: jk-writing-style
description: Routing shim for Alberto Schiabel's writing skills. Use when a prompt or document names jk-writing-style, or when the task is writing or editing prose as Alberto and the target is unclear. Routes work communication (Linear, Slack, PRs, RFCs, incident summaries, status updates, handoffs) to jk-work-writing, and public writing (blog posts, engineering reports, website copy, tweets, talks, newsletters, case studies, bios) to jk-editorial.
---

# jk-writing-style

This skill no longer holds rules. Load the skill that matches the target and follow it.

| Target | Load |
| --- | --- |
| Linear update, Slack message, PR description, RFC or design note, incident summary, status update, handoff | `jk-work-writing` |
| Blog post, engineering report, website copy, tweet or social thread, talk abstract or script, newsletter, case study, bio | `jk-editorial` |

If the target is unclear, ask which audience the text serves. Colleagues who must act on it: `jk-work-writing`. A public reader who is judging Alberto's thinking: `jk-editorial`.

Both skills share these rules.

- Write only facts the input or checked sources establish. Keep supplied, verified, inferred, and unknown apart.
- No em dashes and no semicolons.
- No generated-prose tells, puffery, or closing summaries.

Commit messages, code identifiers, and third-party quotations are out of scope for both.

For content published on jkomyno.dev, `jk-editorial` also points to that repository's `editorial-standard` skill, `VOICE.md`, and `BRAND.md`.
