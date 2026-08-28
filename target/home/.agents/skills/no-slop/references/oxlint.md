# Oxlint policy

Install the bundled source instead of configuring rule names without implementations. The `anti-slop/*` rules are vendored from [`dmmulroy/anti-slop` at `6d53855`](https://github.com/dmmulroy/anti-slop/tree/6d538555cb151d4121ed51a27db81890eacf8ae9), with its MIT license. The `no-slop/*` rules are maintained locally. Both plugins inspect syntax rather than TypeScript types, so they supplement typecheck and boundary tests.

Do not use warning severity. Enable a rule as an error where its contract applies, or leave it disabled and report it as a review heuristic.

## Install

1. Read repository instructions, inspect `git status`, identify the package manager, and locate `oxlint.config.*`, `.oxlintrc*`, or Vite+ configuration.
2. Run `node <skill-directory>/scripts/install.mjs` from the target repository. This copies the plugins to `tools/oxlint/anti-slop/` and `tools/oxlint/no-slop/`. Pass a different tooling root as the first argument when required. The script refuses to overwrite existing copies; use `--force` only after reviewing and preserving local changes.
3. Query current `oxlint` and `@oxlint/plugins` versions from npm and install matching versions as development dependencies with the repository's package manager.
4. Ignore the copied plugin source and local agent directories in lint and formatting. Preserve existing ignores.
5. Register both generic plugins:

   ```ts
   jsPlugins: [
     { name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" },
     { name: "no-slop", specifier: "./tools/oxlint/no-slop/index.ts" },
   ]
   ```

6. Enable the generic rules below as errors. Use file overrides only for a justified directory-level contract.
7. Run the repository's lint command, typecheck, and affected tests. For Vite+, run the full `vp check` after merging lint and format ignores. Fix findings only when the user requested migration or cleanup.
8. Report copied paths, dependency versions, configuration changes, checks, and remaining findings.

## Complete upstream rules

Enable every generic upstream rule:

```json
{
  "anti-slop/no-chained-type-assertions": "error",
  "anti-slop/no-conditional-empty-object-spread": "error",
  "anti-slop/no-known-value-widening": "error",
  "anti-slop/no-module-mocking": "error",
  "anti-slop/no-object-parameters": "error",
  "anti-slop/no-reflect-apply": "error",
  "anti-slop/no-reflect-get": "error",
  "anti-slop/no-runtime-typeof": "error",
  "anti-slop/no-shape-in-symbol-names": "error",
  "anti-slop/no-unknown-parameters": "error",
  "anti-slop/no-unknown-returns": "error",
  "anti-slop/no-unknown-type-aliases": "error",
  "anti-slop/no-unsafe-dictionary-type": "error",
  "anti-slop/no-widen-then-assert": "error",
  "anti-slop/require-safety-comment-for-type-assertion": "error"
}
```

If the repository directly depends on Effect, or the user requests Effect policy, also register `./tools/oxlint/anti-slop/effect/index.ts` as `anti-slop-effect` and enable `anti-slop-effect/no-service-constructor-imports` as an error. Do not infer this from a transitive lockfile entry.

## Local rules

Enable these as errors with the generic plugin:

| Rule | Contract |
| --- | --- |
| `no-slop/no-broad-return-types` | Explicit function returns must provide more evidence than `any`, `object`, or `{}`. |
| `no-slop/no-broad-type-aliases` | An alias must not merely rename `any`, `object`, or `{}`. Upstream covers aliases to `unknown`. |

Enable `no-slop/no-ambient-env-access` for source directories whose environment configuration is already resolved at the composition root. Exclude the small set of files that owns environment reads. Do not enable it globally and then suppress arbitrary consumers.

## Migration constraints

- Keep upstream source unchanged so a later refresh has a readable diff. Keep local rules in `no-slop`.
- Do not suppress rules, weaken severity, add unsafe assertions, or rewrite valid dynamic behavior merely to make lint pass.
- Preserve valid `unknown` at trust boundaries, `typeof` inside parsers and type guards, exact domain uses of `shape`, and intentional metaprogramming through explicit file overrides when an upstream rule would reject them.
- Keep disable directives narrow and state the valid exception.
