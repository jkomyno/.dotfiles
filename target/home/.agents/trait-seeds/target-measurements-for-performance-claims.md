---
name: target-measurements-for-performance-claims
subject: Claims that an implementation improves runtime performance.
requirement: >
  Support a performance claim with measurements of the relevant implementation
  and workload in the target environment. Distinguish measured improvements
  from variation, and label emulator or surrogate results as preliminary.
applicability: >
  Applies to claimed measured gains. Analytical estimates and explicitly labeled
  hypotheses may guide experiments without establishing a performance result.
purpose: Prevent optimistic proxy results from being presented as real gains.
---

Measure the operation whose improvement is claimed, including integration costs
when the claim concerns the whole operation. A component benchmark supports a
component result; it does not by itself establish an end-to-end gain.
