---
name: preserve-version-specific-fixtures
subject: Dependency changes in version-specific compatibility tests and fixtures.
requirement: >
  Preserve the dependency major version that a compatibility case intentionally
  exercises. Do not bulk-upgrade it to a different major merely to align it
  with the application's current dependency.
applicability: >
  Applies while the tested version remains part of the supported contract.
  An explicitly authorized removal or migration of that contract may change
  or remove its fixture.
purpose: Keep dependency upgrades from silently deleting compatibility coverage.
---

A fixture exercising one library major and an application using another may
both be intentional. Inspect the test's purpose before changing its version.
