# jk-build — phase: spec

Goal: produce a written spec the human approves before any code is touched. Specs prevent the "we built the wrong thing" failure mode that costs hours.

## Inputs

The user's request, the current repo state, and any prior conversation. Sometimes a Linear issue, a Slack thread, or a screenshot.

## Protocol

1. **Read first.** Skim the repo's README, AGENTS.md (if present), and the top-level directory layout. Don't ask the human questions the codebase already answers.
2. **Surface what's missing.** Identify what you don't yet know that you'd need to build the thing well. Group questions into:
   - **Intent.** What is the user trying to accomplish? Why now?
   - **Constraints.** Time budget, compatibility, dependencies allowed or forbidden, platforms.
   - **Audience.** Who will use this? An end user? A teammate? A future agent?
   - **Scope.** What's in. What's explicitly out.
   - **Success criteria.** How will we know it worked? A passing test? A green CI? A demo?
   - **Rejected alternatives.** What other approaches were considered? Why were they ruled out?
3. **Ask in batches.** Use `AskUserQuestion` with focused single-select options when there are real choices. Three to four questions per batch is the sweet spot. Don't ask one question at a time and don't ask twelve.
4. **Write the spec.** Markdown, in a SPEC.md or similar local working doc (gitignored if the repo convention says so). Sections: Goals, Non-Goals, Constraints, Decisions, Open Questions. Open Questions should be empty before moving to plan.

## Outputs

A SPEC.md the human has read and confirmed. If the human says "looks good" or equivalent, the spec is stable.

## When to stop and ask vs. when to decide

Stop and ask when:
- A decision affects API surface, persisted data, or external integration.
- Two reasonable approaches both look defensible.
- The cost of guessing wrong is more than one commit's worth of work.

Decide and report when:
- It's a local style or naming choice.
- It's a default value that's easy to flip later.
- The repo's conventions already imply one answer.

Match the cost of asking to the cost of being wrong.
