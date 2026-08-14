# TypeScript

Keep type evidence intact from input to output. Let the compiler prove what it can. Validate the rest at runtime where untrusted data enters.

## Preserve known information

- Prefer inference when the initializer already carries the exact type.
- Use `satisfies` to check a contract without discarding literal keys or values.
- Use `as const` only when literal inference and readonly data match the intended contract.
- Use named domain types for internal parameters and returns.
- Keep discriminants narrow so exhaustive checks stay useful.

Avoid these patterns:

- Chained assertions such as `value as unknown as User`.
- Widening a known value to `unknown`, `object`, or a broad dictionary, then asserting it back.
- Aliases that only hide `unknown`, `any`, `{}`, or `object`.
- Generic parameters that add no caller-controlled variation.
- Structural names such as `UserShape` when a domain role names the concept better. Keep `shape` when geometry, tensors, or another domain uses it precisely.

Preserve registry keys while checking every value:

```ts
const handlers = {
  start: startHandler,
  stop: stopHandler,
} satisfies Record<string, Handler>;

type CommandName = keyof typeof handlers;
```

Use `Record<string, Value>` only for a genuinely open key space. For fixed keys, infer the object or name the key union.

## Normalize boundaries once

- At the composition root, read environment variables, config files, and CLI arguments. Resolve precedence and defaults there.
- Validate and canonicalize that input into one readonly runtime config. Pass each component only the typed values it owns.
- Do not read `process.env` or repeat defaults and fallback logic downstream.
- If configuration reloads at runtime, let one provider own rereads and emit validated snapshots. Consumers still receive normalized config.
- Normalize requests, messages, and job payloads once at each ingress boundary. These values do not exist at process startup.
- Normalize only representations the contract considers equivalent. Preserve distinctions between missing, empty, `false`, `0`, omitted, and `undefined` when behavior differs.
- Accept `unknown` only where untrusted input enters, such as JSON, environment data, storage, or third-party responses.
- Parse with the repository's existing schema or decoder. Do not add a validation dependency for style alone.
- Return a named domain type before data enters business logic. A generic transport or JSON decoder may return `unknown` when it cannot own the domain schema. Parse that result immediately.
- Keep `cause: unknown` when preserving an external error cause.
- Prefer an explicit JSON value type when the contract is JSON, not arbitrary data.
- Keep `typeof`, `in`, and property checks inside a parser or type guard. Do not scatter them through domain code.

## Justify assertions

Replace an assertion with inference, parsing, a type guard, or exhaustive control flow when possible.

When an assertion relies on a runtime invariant the compiler cannot see, place a specific `SAFETY:` comment immediately before it. Name the invariant and the operation that established it.

```ts
// SAFETY: parseUserId validated the canonical UUID form before branding it.
return value as UserId;
```

A comment does not make an unchecked assertion safe. Add or keep runtime validation when the value crosses a trust boundary. Do not add ritual comments for locally obvious compiler limitations. Prefer a named helper when the same assertion repeats.

## Keep behavior direct

- Prefer typed property access and direct function calls over `Reflect.get` and `Reflect.apply`.
- Model dynamic dispatch with a typed registry or named interface.
- Build optional properties explicitly when omission differs from `undefined`.
- Avoid conditional spreads that use `{}` as hidden control flow.
- Remove defensive branches for states the type system and constructor already exclude.
- Avoid wrappers that only rename a call, type, or value without owning policy.

## Test contracts

- Test changed behavior, bug regressions, and previously untested public contracts.
- Exercise parsing where untrusted data enters and assert the domain result or error.
- Pass dependencies through real parameters or interfaces. Prefer faithful test implementations. Use a module mock only when the dependency cannot be replaced without an unrelated production redesign, and keep the mock local to the test.
- Do not test private call order, copied implementation logic, or impossible states.
- Keep the narrowest test that proves the contract.

## Write useful comments

- Explain a constraint, invariant, tradeoff, or external contract that the code cannot express.
- Remove comments that narrate the next line, announce a section, or claim quality without proof.
- Keep issue links only when they preserve necessary context.

## Scan candidates

Use a text scan to find candidates, then inspect every match in context:

```bash
rg -n --glob '*.ts' --glob '*.tsx' \
  'as unknown as|Record<string, unknown>|:\s*(unknown|object)\b|Reflect\.(get|apply)|\b(vi|jest)\.(mock|doMock|unstable_mockModule)\b|\btypeof\b|[A-Za-z0-9_]Shape\b|process\.env\b'
```

Do not auto-fix the matches. A boundary parser, an open dictionary, or a local test convention may be valid. Treat the scan as discovery, not enforcement.

Run the repository's narrow typecheck, lint command, and relevant tests after editing. Inspect the final diff for widened types, new assertions, hidden branches, and unrelated churn.
