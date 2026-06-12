---
name: sync-skills
description: Sync vendored third-party skills against their upstream repositories, re-apply local patches, and flag new upstream skills. Use when the user says "sync skills", "update vendored skills", or "check for skill updates".
---

# Sync Vendored Skills

Third-party skills are vendored into the dotfiles repository under `home/dot_agents/skills/exact_<name>/` and deployed by chezmoi to `~/.agents/skills/<name>/`. `manifest.json` in this skill's directory maps each vendored skill to its upstream repository and in-repo path. This skill keeps the vendored copies in sync with upstream while preserving deliberate local modifications as patch files.

Inspired by dmmulroy's `sync-pocock-skills`, generalized to many upstreams.

## Quick start

Always operate on the dotfiles **source checkout**, never on the deployed `~/.agents/skills`, so accepted changes land in git:

```bash
DOTFILES="${DOTFILES:-$HOME/work/me/dotfiles}"
SYNC_ROOT="$DOTFILES/home/dot_agents/skills/exact_sync-skills"
bash "$SYNC_ROOT/scripts/sync.sh" --keep-upstream
```

## Workflow

### 1. Analyse

Run `sync.sh` as above and parse the output sections:

- **UPSTREAM_CHANGES** — per-skill list of files that differ from upstream-plus-our-patches. Annotations: `(changed, no patch)`, `(upstream changed, has patch)`, `(patch conflict)`, `(new file upstream)`, `(removed upstream)`.
- **MISSING_UPSTREAM** — a manifest entry whose path no longer exists upstream; the repo restructured. Locate the skill's new path in the retained clone and update `manifest.json`.
- **NEW_SKILLS** — skills available in repos we already track but do not vendor. Ask the user which to add; append rejected ones to `patches/excluded.txt`.
- **UPSTREAM_DIRS** — retained clone paths (with `--keep-upstream`) for reading upstream files.

### 2. Apply upstream changes

For each `CHANGED:` entry:

- `(changed, no patch)` / `(new file upstream)` — safe to take upstream. Run:

  ```bash
  bash "$SYNC_ROOT/scripts/apply-upstream.sh" <skill_name> <upstream_skill_dir>
  ```

- `(upstream changed, has patch)` — `apply-upstream.sh` copies upstream and re-applies the stored patch automatically. If it prints `PATCH_CONFLICT`, read both versions, resolve in the vendored copy, then regenerate the patch with `make-patch.sh`.
- `(patch conflict)` — same manual resolution: read upstream and ours, merge, regenerate the patch.
- `(removed upstream)` — flag to the user; suggest deleting the file or the whole skill (and its manifest entry).

`<upstream_skill_dir>` is `<clone dir from UPSTREAM_DIRS>/<path from manifest.json>`.

### 3. Record local modifications

When we deliberately diverge from upstream (ours-only edits to a vendored file), store the divergence as a patch so the next sync re-applies it:

```bash
bash "$SYNC_ROOT/scripts/make-patch.sh" <skill_name> <rel_path> <upstream_file> <our_file>
```

Patches live in `patches/<skill_name>__<rel_path>.patch` with stable `upstream/...`/`ours/...` labels, so they do not churn when temp clone paths change.

### 4. Add a new skill

1. Add an entry to `manifest.json` with `repo` and `path` (the directory containing `SKILL.md`).
2. Run `apply-upstream.sh <name> <upstream_skill_dir>` to vendor it under `exact_<name>/`.
3. Add `symlink_<name>.tmpl` files to `home/dot_claude/skills/` and `home/dot_codex/skills/` (copy an existing one; they all point at `~/.agents/skills/<name>`).

### 5. Verify and summarise

1. Rerun `sync.sh` and confirm `UPSTREAM_CHANGES` is clean (or only intentionally-divergent entries remain).
2. Run `git -C "$DOTFILES" diff --stat` and read the per-skill diffs before reporting; separate metadata-only changes from instruction-body changes.
3. Remind the user that deployed copies in `~/.agents/skills` update on the next `chezmoi apply`.

Report: skills updated, patches created or re-applied, conflicts needing attention, new skills offered/excluded, and the net diff.

## File layout

```
exact_sync-skills/
├── SKILL.md                  # This file
├── manifest.json             # skill name -> { repo, path }
├── scripts/
│   ├── sync.sh               # Analyse all upstreams vs our vendored copies
│   ├── apply-upstream.sh     # Replace vendored copy with upstream + re-apply patches
│   └── make-patch.sh         # Record a local modification as a stable patch
└── patches/
    ├── excluded.txt          # Upstream skills we never offer to vendor
    └── <skill>__<file>.patch # Local modifications, re-applied on every sync
```
