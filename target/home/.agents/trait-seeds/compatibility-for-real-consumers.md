---
name: compatibility-for-real-consumers
subject: Compatibility layers retained during an authorized interface cleanup.
requirement: >
  Retain compatibility behavior for an identified supported consumer or
  published contract. When the owner explicitly confirms that the interface is
  unreleased and has no users, remove obsolete interfaces directly rather than
  inventing a deprecation path for them.
applicability: >
  Applies to an authorized cleanup with established release and consumer status.
  Never assume an interface has no users because usage evidence is missing.
  Published APIs, data formats, and independently used internal contracts may
  require compatibility.
purpose: Avoid maintaining obsolete interfaces without discarding real obligations.
---

Missing consumer context makes the assessment inconclusive. This rule does not
authorize removing a public API or expanding the requested cleanup.
