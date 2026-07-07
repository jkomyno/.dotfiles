---
title: "feat: w/d/dot shell shortcuts for zsh and fish"
date: 2026-07-07
artifact_contract: ce-unified-plan/v1
artifact_readiness: implementation-ready
execution: code
product_contract_source: ce-plan-bootstrap
plan_type: feat
depth: lightweight
---

# feat: `w` / `d` / `dot` shell shortcuts for zsh and fish

## Summary

Add three interactive shortcuts to both managed shells:

- **`w`** → `cd ~/work`
- **`d`** → `cd ~/work/me/.dotfiles`
- **`dot …`** → run the dotfiles `just` from *anywhere*, leaving the current directory unchanged (so `dot update` works from any cwd and returns you where you were).

The work is purely additive shell config placed into the repo's existing per-shell conventions. No scripts, recipes, or setup flow change.

---

## Problem Frame

Running dotfiles maintenance today means `cd`-ing into the repo, running `just <recipe>`, then `cd`-ing back. The user wants one-key navigation (`w`, `d`) and a location-independent runner (`dot`) whose defining constraint is that **the interactive shell must end up in the original directory** after a command like `dot update` finishes — including when it fails or is interrupted.

**Key constraint validated during planning:** the justfile's recipes depend on the working directory — e.g. the `diff` recipe uses `$PWD`, and most recipes call scripts by repo-relative path (`@scripts/dotfiles/…`). So `dot` must reproduce "run `just` from inside the repo" faithfully, not merely invoke the binary.

---

## Requirements

- **R1** — `w` changes the current shell's directory to `~/work` in both zsh and fish.
- **R2** — `d` changes the current shell's directory to `~/work/me/.dotfiles` in both shells.
- **R3** — `dot <args>` runs the dotfiles `just` with `<args>` as if invoked from the repo root, from any current directory.
- **R4** — after `dot <args>` returns, the interactive shell's cwd is exactly what it was before — including on non-zero exit and on Ctrl-C.
- **R5** — bare `dot` (no args) lists available recipes (the justfile's default recipe).
- **R6** — each shortcut lives in that shell's established convention so it loads automatically with no manual `source`.

---

## Key Technical Decisions

### KTD1 — `dot` uses `just`'s directory flags, never `cd`

`dot` invokes:

```
command just --working-directory ~/work/me/.dotfiles --justfile ~/work/me/.dotfiles/justfile <args>
```

**Why, and why not the alternatives:**

- **`--working-directory` sets recipe cwd to the repo**, so `$PWD`-dependent and relative-path recipes resolve correctly. *Validated empirically:* run from `/tmp`, `just --working-directory <repo> --justfile <repo>/justfile status` executed `git status --short` against the repo (returned the repo's dirty files, exit 0).
- **The interactive shell's cwd is never touched**, so R4 (return-to-original) is satisfied structurally — there is no window in which cwd changed, so failure or Ctrl-C cannot strand you in the repo. A `cd repo && … ` / `pushd`/`popd` approach has exactly that failure window (a SIGINT during `just` can skip the restoring `cd`), which is the behavior the user explicitly wants to avoid.
- **It is byte-identical across zsh and fish**, avoiding fish's lack of `( … )` subshell semantics. A zsh subshell (`( cd … && just )`) is equally safe in zsh but has no clean fish twin; the flag form keeps both shells on the same mechanism.
- `command just` bypasses any alias/function named `just`.

### KTD2 — zsh via auto-sourced aliases; fish via autoloaded functions

Match each shell's existing pattern rather than introducing a new one:

- **zsh** — the aliases in `~/.config/zsh/aliases.d/*.zsh` are all sourced at startup (`.zshrc:137`). All three shortcuts are plain aliases here (trailing args append to an alias, so `dot update` → `… just … update`). This needs **no `.zshrc` edit** — unlike the autoloaded `functions/` dir, which requires adding names to the `autoload -Uz …` line (`.zshrc:145`).
- **fish** — fish autoloads `~/.config/fish/functions/<name>.fish` on first call. Each shortcut is one function file, mirroring existing trivial functions (`pt.fish`, `p.fish`, `ls.fish`).

### KTD3 — hardcode the canonical `~/work/me/.dotfiles`

Per the user's request and confirmed against `README.md` (`README.md:28`/`:50` spell out `~/work/me/.dotfiles`) and the root `setup.sh` (which fetches the repo there), the canonical checkout path is `~/work/me/.dotfiles` (with the dot); that is also what the m4pro host uses. Single hardcoded path, no runtime probing. See **Operational Notes** for the one machine that currently diverges.

---

## Output Structure

New files (all under `target/home`, the mise dotfiles source tree):

```
target/home/.config/zsh/aliases.d/
  nav.zsh              # w, d
  dot.zsh              # dot
target/home/.config/fish/functions/
  w.fish
  d.fish
  dot.fish
```

---

## Implementation Units

### U1. zsh shortcuts (`w`, `d`, `dot`)

- **Goal:** add the three shortcuts as auto-sourced zsh aliases. Advances R1, R2, R3, R4, R5, R6.
- **Dependencies:** none.
- **Files:**
  - `target/home/.config/zsh/aliases.d/nav.zsh` (create) — `w`, `d`
  - `target/home/.config/zsh/aliases.d/dot.zsh` (create) — `dot`
- **Approach:** two small alias files consistent with the existing `git-shortcuts.zsh` / `ls.zsh` granularity. `~` tilde-expands when a zsh alias runs, so paths can stay readable. No `.zshrc` change.
- **Patterns to follow:** `target/home/.config/zsh/aliases.d/ls.zsh`, `target/home/.config/zsh/aliases.d/git-shortcuts.zsh` (file-level comment + `alias name='…'`).
- **Technical design** *(directional guidance, not spec):*

  ```zsh
  # nav.zsh — jump to the work tree and the dotfiles repo
  alias w='cd ~/work'
  alias d='cd ~/work/me/.dotfiles'
  ```

  ```zsh
  # dot.zsh — run the dotfiles `just` from anywhere, without changing cwd.
  # --working-directory makes $PWD/relative-path recipes resolve against the
  # repo; the interactive shell's cwd is never touched, so it "returns" for
  # free. Bare `dot` runs the justfile default recipe (lists recipes).
  alias dot='command just --working-directory ~/work/me/.dotfiles --justfile ~/work/me/.dotfiles/justfile'
  ```
- **Execution note:** shell config — prefer runtime smoke verification (source the file, run the shortcut) over any unit harness.
- **Test scenarios:** `Test expectation: none — shell config; verified by the runtime smoke checks in Verification.`

### U2. fish shortcuts (`w`, `d`, `dot`)

- **Goal:** add the three shortcuts as autoloaded fish functions. Advances R1, R2, R3, R4, R5, R6.
- **Dependencies:** none (independent of U1).
- **Files:**
  - `target/home/.config/fish/functions/w.fish` (create)
  - `target/home/.config/fish/functions/d.fish` (create)
  - `target/home/.config/fish/functions/dot.fish` (create)
- **Approach:** one function per file, fish's native autoload convention. `$argv` forwards args for `dot`; `~` expands in fish argument position.
- **Patterns to follow:** `target/home/.config/fish/functions/pt.fish`, `.../p.fish` (function with `-d` description), `.../ls.fish` (uses `command`/`$argv`).
- **Technical design** *(directional guidance, not spec):*

  ```fish
  # w.fish
  function w -d "cd to ~/work"
      cd ~/work
  end
  ```

  ```fish
  # d.fish
  function d -d "cd to the dotfiles repo"
      cd ~/work/me/.dotfiles
  end
  ```

  ```fish
  # dot.fish — run the dotfiles `just` from anywhere, cwd unchanged
  function dot -d "run just in the dotfiles repo"
      command just --working-directory ~/work/me/.dotfiles --justfile ~/work/me/.dotfiles/justfile $argv
  end
  ```
- **Execution note:** shell config — runtime smoke verification, same as U1.
- **Test scenarios:** `Test expectation: none — shell config; verified by the runtime smoke checks in Verification.`

---

## Verification

Deploy the source tree to `$HOME` first (edits under `target/home` are not live until applied): `just diff` to preview, then `mise dotfiles apply`.

Then, in a fresh shell of each type:

0. **Prerequisite (non-canonical hosts only)** — if this host's checkout is not at `~/work/me/.dotfiles` (e.g. this machine's `~/work/me/dotfiles`), create the reconcile symlink from **Operational Notes** first, or steps 2–6 fail on a missing directory/justfile before you reach `w`.
1. **`w`** — from any directory, `w` leaves you in `~/work` (`pwd` confirms).
2. **`d`** — `d` leaves you in `~/work/me/.dotfiles`.
3. **`dot` bare** — from e.g. `/tmp`, `dot` prints the recipe list; `pwd` still `/tmp`.
4. **`dot <recipe>`** — from `/tmp`, `dot status` prints the repo's `git status --short`; `pwd` still `/tmp`.
5. **Return-on-failure** — from `/tmp`, `dot <nonexistent-recipe>` (non-zero exit); `pwd` still `/tmp`.
6. **Return-on-interrupt** — from `/tmp`, start a long recipe and Ctrl-C it; `pwd` still `/tmp`.
7. Repeat 1–6 in the other shell.

---

## Operational Notes

- **This machine diverges from canonical (one-time fix).** This checkout is at `~/work/me/dotfiles` (no dot); the shortcuts target `~/work/me/.dotfiles`. Per KTD3 the plan keeps the canonical path — reconcile this host once, outside the tracked tree, e.g. `ln -s ~/work/me/dotfiles ~/work/me/.dotfiles` (or rename the checkout). The m4pro host already uses `.dotfiles` and needs nothing.
- **Chicken-and-egg on first apply.** `dot` can't be used to apply the very change that defines it — run `mise dotfiles apply` from the repo (or `just`) for the initial deploy.

---

## Scope Boundaries

**In scope:** the five new files above (zsh aliases + fish functions) and their runtime verification.

**Deferred to Follow-Up Work:**
- Documenting the shortcuts in `README.md` — nice-to-have, not requested.
- A bash equivalent — bash is not a managed interactive shell here.
- Tab-completion of `just` recipes under the `dot` name — `just`'s own completion is unaffected; wrapping it is extra scope.

**Out of scope:** changes to `justfile` recipes, `setup.sh`, or the mise dotfiles mechanism.

---

## Sources & Research

- `README.md:28`/`:50` and root `setup.sh` (canonical `~/work/me/.dotfiles` path).
- `.zshrc:137` (aliases.d auto-source), `.zshrc:145` (functions autoload line).
- `target/home/.config/fish/functions/` (per-function autoload convention).
- `justfile:1` (`set shell`), `diff` recipe (`$PWD` dependency) — motivates KTD1.
- Empirical: `just 1.54.0`, `--working-directory` + `--justfile` from `/tmp` runs recipes against the repo with cwd unchanged (validated `status` recipe).
