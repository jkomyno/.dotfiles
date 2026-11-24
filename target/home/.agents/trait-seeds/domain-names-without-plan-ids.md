---
name: domain-names-without-plan-ids
subject: Identifiers and explanatory comments in source code and tests.
requirement: >
  Use domain or behavior terminology that a maintainer can understand from the
  code. Do not embed identifiers whose only meaning comes from a temporary
  agent plan.
applicability: >
  Requirement IDs may remain in planning documents. Established external
  standard identifiers, public issue references, and identifiers required by
  the product are not temporary plan labels.
purpose: Keep shipped code understandable independently of an agent session.
---

Name a test after the behavior it proves. Keep temporary plan-to-implementation
tracking in planning artifacts.
