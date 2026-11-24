---
name: bounded-readiness-waits
subject: Tests waiting for asynchronous work to become observable.
requirement: >
  Synchronize on the actual readiness condition using an event, signal, or
  condition-based wait with a bounded failure path. Do not use an arbitrary
  number of scheduler yields as evidence that the work is ready.
applicability: >
  Applies when readiness matters to the assertion. Fixed steps or delays are
  valid when scheduler behavior or elapsed time is itself the tested contract.
purpose: Prevent scheduling accidents from determining test outcomes.
---

Use the project's existing asynchronous primitives. A bounded predicate-based
repeat can be appropriate when there is no event to await; do not build a new
synchronization framework solely for one test.
