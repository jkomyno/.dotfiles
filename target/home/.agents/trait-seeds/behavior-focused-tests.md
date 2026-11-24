---
name: behavior-focused-tests
subject: Assertions in software tests.
requirement: >
  Each test must distinguish a relevant behavior, regression, or supported
  contract from an incorrect implementation. Do not add assertions that merely
  repeat implementation constants or pin an incidental toolchain version.
applicability: >
  Exact versions, constants, ordering, and internal details may be asserted when
  they are the contract or necessary to expose the regression. Integration and
  compatibility fixtures can provide real behavioral evidence.
purpose: Keep tests informative without creating maintenance for incidental details.
---

An assertion that the runtime major version equals today's local version is not
a product test unless that exact version is part of the supported contract.
This rule does not authorize deleting useful fixtures or weakening a failing
regression test.
