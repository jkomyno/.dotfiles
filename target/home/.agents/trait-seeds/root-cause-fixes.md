---
name: root-cause-fixes
subject: A proposed repair for an observed software defect.
requirement: >
  Address the demonstrated cause of the defect at the component that owns it.
  Do not substitute an additional workaround for a causal repair that is
  available within the task's scope.
applicability: >
  A temporary mitigation is valid when the cause cannot yet be repaired in
  scope; state that limitation. If the failure evidence is unavailable, do not
  infer that a causal repair has or has not been made.
purpose: Avoid accumulating special cases around an unresolved defect.
---

The bug report, reproduction, and changed behavior supply context for this
assessment. A source excerpt alone may be insufficient to judge the cause.
