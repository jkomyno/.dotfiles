---
name: structured-internal-values
subject: Internal values that combine a category with a domain identifier.
requirement: >
  Preserve the category and identifier in a typed tuple, object, or enum instead
  of concatenating them into a string and then parsing that same string back
  apart inside the application.
applicability: >
  Applies to internal representations whose fields are already known. Text
  serialization remains appropriate at CLI, storage, logging, and protocol
  boundaries that require it.
purpose: Make invalid combinations harder to express and avoid unnecessary parsing.
---

For example, keep a typed category and name together until an output formatter
needs their textual representation. Do not introduce a class hierarchy for a
pair of values.
