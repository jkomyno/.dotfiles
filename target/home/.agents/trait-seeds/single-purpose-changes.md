---
name: single-purpose-changes
subject: The scope of a patch or pull request.
requirement: >
  Keep the change focused on one reviewable outcome. Move an independent
  refactor, feature, or unrelated fix into a separate change when the requested
  outcome does not depend on it.
applicability: >
  Coupled changes may stay together when separating them would break correctness
  or hide a required migration. An explicitly requested broader refactor is
  within scope.
purpose: Make the reason for each changed part clear to a reviewer.
---

For a targeted bug fix, include the smallest coherent repair and relevant
verification. Scope is determined by dependencies and the requested outcome,
not a fixed line-count limit.
