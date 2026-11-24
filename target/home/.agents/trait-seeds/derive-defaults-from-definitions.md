---
name: derive-defaults-from-definitions
subject: Defaults or metadata repeated across command definitions and their consumers.
requirement: >
  Derive consumers' defaults and metadata from the definition that owns them.
  Do not independently redeclare the same command flags and default values in
  telemetry or another secondary registry.
applicability: >
  Applies when consumers need the same semantics. A deliberately different
  public schema or transformed representation may have its own definition,
  with the mapping made explicit.
purpose: Prevent duplicated declarations from drifting apart.
---

A shared definition should expose the information its consumers actually need.
Avoid a generic registry framework when a small typed value is sufficient.
