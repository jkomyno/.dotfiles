# Oxlint policy

The `anti-slop/*` identifiers below are custom JavaScript plugin rules. They are not part of Oxlint core. The current rules inspect syntax rather than TypeScript types, so they do not replace typecheck or boundary tests. Treat them as policy candidates and keep this local policy independent from upstream defaults.

Do not use warning severity. A rule either has enough signal to block a change or remains a review heuristic.

## Default errors

Enable these rules when the repository has the plugin. Their violations discard type evidence with few legitimate exceptions.

| Rule | Required response |
| --- | --- |
| `anti-slop/no-chained-type-assertions` | Replace assertion chains with inference, parsing, or one justified assertion. |
| `anti-slop/no-known-value-widening` | Preserve inferred keys and values with inference, `satisfies`, or a named owner contract. |
| `anti-slop/no-object-parameters` | Accept a useful domain type or a caller-controlled generic. |
| `anti-slop/no-unknown-type-aliases` | Keep `unknown` visible at the boundary instead of hiding it behind an alias. |
| `anti-slop/no-widen-then-assert` | Preserve the original precise type or parse once before domain use. |

## Scoped errors

Enable these as errors only after the repository satisfies the stated condition. Use file overrides when the exception belongs to a clear directory.

| Rule | Enable when |
| --- | --- |
| `anti-slop/no-conditional-empty-object-spread` | The project treats omitted properties as a contract and prefers explicit object construction. |
| `anti-slop/no-module-mocking` | Dependencies already enter through parameters, interfaces, or replaceable services. Do not force a production redesign during a test cleanup. |
| `anti-slop/no-reflect-apply` | Application code has no intentional metaprogramming or compatibility adapter that requires reflective calls. |
| `anti-slop/no-reflect-get` | Dynamic property access is isolated behind typed registries or parsed boundary objects. |
| `anti-slop/no-unknown-returns` | Raw transport decoders and generic JSON utilities are excluded or already return a concrete JSON type. |
| `anti-slop/no-unsafe-dictionary-type` | Open metadata and JSON contracts use a concrete value type or are parsed before domain use. |
| `anti-slop/require-safety-comment-for-type-assertion` | Existing assertions have been reviewed and the team will reject comments that do not name a checked invariant. |

## Review only

Do not enable these globally. Their syntax also represents valid TypeScript or precise domain language.

| Rule | Review decision |
| --- | --- |
| `anti-slop/no-runtime-typeof` | Keep runtime checks inside parsers, assertion functions, and type guards. TypeScript uses these checks for sound narrowing. |
| `anti-slop/no-shape-in-symbol-names` | Prefer a domain role, but keep `shape` when it is the exact domain term. |
| `anti-slop/no-unknown-parameters` | Permit `unknown` at genuine trust boundaries. Require parsing before business logic. |

## Adopt the policy

1. Inspect the repository's existing Oxlint config, boundary modules, test architecture, and intentional metaprogramming.
2. Confirm that the custom plugin implementation exists. If it is absent, ask before vendoring code or changing dependencies. Do not add rule names that Oxlint cannot load.
3. Pin vendored plugin source to a reviewed commit and retain its license. Keep `oxlint` and `@oxlint/plugins` compatible with that source.
4. Enable the default rules as errors.
5. Enable scoped rules only where their preconditions hold.
6. Run lint, typecheck, and the tests affected by each migration. Fix the ownership or parsing problem instead of laundering the type.
7. Keep any disable directive narrow and explain the valid exception.

This policy was compared with [`dmmulroy/anti-slop` at `446268e`](https://github.com/dmmulroy/anti-slop/tree/446268e5d15baa968eaec669ff65358d36ae6259). Reassess new upstream rules before adopting them.
