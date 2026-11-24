---
name: typed-domain-boundaries
subject: Data passed from external input into typed application logic.
requirement: >
  Parse untrusted input with the project's existing decoder before passing it
  into domain logic. Internal helpers must accept the known domain type and
  preserve its guarantees; do not replace parsing with a type assertion or
  repeat primitive type checks on values already guaranteed by the contract.
applicability: >
  Applies where the application owns the input contract. Generic transport
  decoders may return unknown for their caller to parse, and genuinely untyped
  or externally mutable data still needs validation.
purpose: Keep uncertainty at its entry point and preserve type evidence downstream.
---

Use the schema library already adopted by the project. Effect-specific
preferences apply only in projects that have adopted Effect. Preserve meaningful
differences between omitted, empty, false, and zero values.
