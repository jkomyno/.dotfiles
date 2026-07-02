# mise dotfiles migration

This repository is moving from a chezmoi-managed source tree toward a
mise-managed, target-shaped dotfiles tree.

## Context

- This checkout has not necessarily been installed on the current machine.
  Do not use the current `$HOME` as evidence that the repository is stale or
  safe to apply.
- The current deployed-file manager is chezmoi. The source tree under `home/`
  uses chezmoi's source-state names such as `dot_config`, `exact_`, `private_`,
  `symlink_`, and `.tmpl`.
- The intended destination is a source tree that reads like the target tree,
  with files such as `target/home/.zshrc` and
  `target/home/.config/fish/config.fish`.
- mise's experimental `[dotfiles]` config is the candidate replacement for
  whole-file placement. It keeps target paths explicit in `mise.toml` and
  supports symlink, copy, and template modes.

## Goals

- Make the source layout easy to inspect without remembering chezmoi's filename
  encoding.
- Keep blank-machine bootstrap reproducible.
- Preserve the existing package ownership model:
  - mise owns language runtimes and developer CLIs.
  - nanobrew owns GUI apps, fonts, and exceptional formulae.
  - no CLI is duplicated between mise and nanobrew.
- Keep verification non-mutating until the setup entrypoint is intentionally
  switched.

## Non-goals

- Do not immediately remove chezmoi.
- Do not change package ownership while migrating the dotfile placement layer.
- Do not apply this repository to the current `$HOME` as part of migration
  validation.
- Do not migrate secrets, authentication state, caches, or machine-private
  runtime data into the repository.

## Stages

## Current status

- Stage 0 is in progress: repo-local status commands now avoid misleading
  deployed-home comparisons when this checkout is not the active chezmoi
  source.
- Stage 1 is complete enough to proceed: `mise 2026.6.14` exposes the
  experimental `dotfiles` command, and `just dotfiles-spike` proves it against
  a temporary HOME.
- Stage 2 has mirrored slices for Starship, ripgrep, Ghostty, hunk, ghui,
  ccstatusline, tmux, Neovim, utility config, curated agent adapters, and the
  plain zsh/fish shell files. These now exist under `target/home/...` and are
  mapped through root `[dotfiles]` entries.
- `just dotfiles-mirror-check` guards the temporary dual-source phase by
  checking that mirrored target files still match their current chezmoi
  sources.
- Stage 3 capability probing is tracked by `just dotfiles-capabilities`.

Next migration step: continue Stage 2 with additional individual plain files.
Good candidates are grouped Git config files that are not templates, or
remaining simple app config. Avoid Git signing, SSH, GitHub CLI private config,
app-private symlink targets, and sensitive templates until they get a dedicated
migration pass.

### 0. Guardrails

Make the current repository honest about installation state.

Acceptance:

- `just status` always reports the source checkout status.
- `just status` and `just diff` only compare deployed-home drift when the
  active chezmoi source is this checkout's `home/` source root.
- Forced deployed-home comparison is still available for diagnostics through an
  explicit environment variable.
- `just doctor` remains non-mutating.

### 1. mise dotfiles capability spike

Prove the local mise version supports the required dotfiles commands before
moving real config.

Acceptance:

- `just dotfiles-spike` fails clearly when the local mise does not expose
  the experimental `dotfiles` command.
- `MISE_EXPERIMENTAL=true mise dotfiles status --help` works on the target
  mise version.
- A disposable spike maps one low-risk file from a target-shaped source path to
  a temporary home directory.
- The spike uses only non-mutating or disposable commands, for example:

```sh
just dotfiles-spike
scripts/dotfiles/mise-dotfiles-spike.sh --install
```

### 2. Target-shaped mirror

Introduce the new source layout without changing setup behavior.

Proposed layout:

```text
target/
  home/
    .zshrc
    .zprofile.tmpl
    .config/
      fish/
      ghostty/
      git/
      mise/
```

Acceptance:

- Start with a small, non-secret slice such as Starship, ripgrep, or tmux.
- Keep the existing chezmoi source files in place until the equivalent
  `[dotfiles]` entry is verified.
- Add a generated mapping in `mise.toml` or a hand-written first slice that
  clearly pairs each target path with its source path.
- `just dotfiles-check` verifies the mirrored slice against a temporary HOME
  without writing to the real `$HOME`.

### 3. Templates and symlinks

Replace chezmoi-specific file behavior with mise-native behavior or small
scripts.

Capability findings for `mise 2026.6.14`:

- `mode = "symlink"` creates symlinks for files.
- `mode = "copy"` creates regular files.
- `mode = "template"` renders templates and can read environment values through
  `env.*`.
- `mode = "symlink"` can point a target directory at a source directory.
- `mise dotfiles apply` refuses to overwrite existing whole-file targets unless
  `--force` is passed.
- `mise dotfiles apply --force` replaces conflicting whole-file targets.

Acceptance:

- Simple symlinks become `[dotfiles]` entries with `mode = "symlink"`.
- Files that tools rewrite in place use `mode = "copy"`.
- Files that need environment-specific rendering use `mode = "template"`.
- Directory overlays need separate proof before migration. If mise dotfiles
  does not support a safe overlay mode, keep those directories on chezmoi or
  manage their individual files explicitly.

### 4. Hooks to tasks

Move bootstrap sequencing out of `.chezmoiscripts` and into mise tasks while
keeping implementation scripts under `install/`.

Acceptance:

- The scripts under `install/` remain directly runnable.
- mise task files are thin wrappers with clear dependencies.
- macOS-only work stays guarded by OS and architecture checks.
- Package installs and macOS defaults stay explicit, idempotent, and easy to
  dry-run where the underlying tool supports it.

### 5. Setup switch

Switch `setup.sh` from installing/running chezmoi to installing/running mise.

Acceptance:

- `setup.sh` still supports a brand-new Apple Silicon Mac with only Terminal
  and `curl`.
- The repository still lands at `~/work/me/dotfiles` by default.
- Setup runs the staged mise tasks and dotfiles apply path.
- Chezmoi remains available as a fallback until the new setup path has been
  tested in an isolated macOS user account or VM.

### 6. Chezmoi removal

Remove the old source-state tree after the mise path owns the full supported
surface.

Acceptance:

- `.chezmoiroot`, `.chezmoi.yaml.tmpl`, `.chezmoiignore`,
  `.chezmoitemplates`, and `.chezmoiscripts` are gone.
- `home/dot_*`, `home/private_*`, `home/symlink_*`, and `home/exact_*`
  equivalents have either moved to `target/home` or been explicitly dropped.
- README and maintenance scripts no longer mention chezmoi except in migration
  history.

## Verification

Prefer these checks while the repo is not installed locally:

```sh
git status --short
just doctor
just status
```

Use deployed-home comparisons only on a machine where this checkout is the
active dotfiles source. To force a comparison anyway:

```sh
DOTFILES_FORCE_CHEZMOI_DRIFT=1 just status
DOTFILES_FORCE_CHEZMOI_DRIFT=1 just diff
```
